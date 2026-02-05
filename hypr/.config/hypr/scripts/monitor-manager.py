#!/usr/bin/env python3
"""
Monitor Manager for Hyprland
Visual GTK4 application for managing monitor configuration
Supports drag-and-drop monitor positioning
"""

import gi
gi.require_version('Gtk', '4.0')
gi.require_version('Adw', '1')
from gi.repository import Gtk, Adw, Gdk, GLib
import subprocess
import json
import math
import os
from pathlib import Path

# Presets directory
PRESETS_DIR = Path.home() / ".config" / "hypr" / "monitor-presets"


def ensure_presets_dir():
    """Create presets directory if it doesn't exist"""
    PRESETS_DIR.mkdir(parents=True, exist_ok=True)


def get_presets():
    """Get list of saved presets"""
    if not PRESETS_DIR.exists():
        return []
    return sorted([f.stem for f in PRESETS_DIR.glob("*.json")])


def save_preset(name, monitors):
    """Save current monitor configuration as a preset"""
    ensure_presets_dir()
    preset_data = {
        "name": name,
        "monitors": []
    }
    for m in monitors:
        preset_data["monitors"].append({
            "name": m.name,
            "x": m.pending_x,
            "y": m.pending_y,
            "scale": m.scale,
            "transform": m.transform,
            "disabled": m.disabled
        })

    preset_file = PRESETS_DIR / f"{name}.json"
    with open(preset_file, 'w') as f:
        json.dump(preset_data, f, indent=2)
    return True


def load_preset(name):
    """Load a preset configuration"""
    preset_file = PRESETS_DIR / f"{name}.json"
    if not preset_file.exists():
        return None
    with open(preset_file, 'r') as f:
        return json.load(f)


def delete_preset(name):
    """Delete a preset"""
    preset_file = PRESETS_DIR / f"{name}.json"
    if preset_file.exists():
        preset_file.unlink()
        return True
    return False


class Monitor:
    """Represents a monitor's configuration"""
    def __init__(self, data):
        self.name = data['name']
        self.description = data.get('description', '')
        self.make = data.get('make', '')
        self.model = data.get('model', '')
        self.width = data['width']
        self.height = data['height']
        self.refresh_rate = data['refreshRate']
        self.x = data['x']
        self.y = data['y']
        self.scale = data['scale']
        self.transform = data['transform']
        self.disabled = data.get('disabled', False)
        self.available_modes = self._parse_modes(data.get('availableModes', []))
        self.focused = data.get('focused', False)
        # For drag operations - track pending position
        self.pending_x = self.x
        self.pending_y = self.y

    def _parse_modes(self, modes_str):
        """Parse available modes from hyprctl output"""
        modes = []
        if isinstance(modes_str, list):
            for mode in modes_str:
                if isinstance(mode, str) and 'x' in mode and '@' in mode:
                    try:
                        res, rate = mode.split('@')
                        w, h = res.split('x')
                        modes.append({
                            'width': int(w),
                            'height': int(h),
                            'rate': float(rate.replace('Hz', ''))
                        })
                    except:
                        pass
        return modes

    def get_display_name(self):
        """Get a friendly display name"""
        if self.model and self.model != self.name:
            return f"{self.name} ({self.model})"
        return self.name

    def get_effective_size(self):
        """Get size accounting for rotation and scale"""
        w, h = self.width, self.height
        if self.transform in [1, 3, 5, 7]:  # 90 or 270 degree rotations
            w, h = h, w
        # Account for scale
        return (int(w / self.scale), int(h / self.scale))


class MonitorPreview(Gtk.DrawingArea):
    """Canvas showing monitor layout preview with drag support"""

    def __init__(self, app):
        super().__init__()
        self.app = app
        self.monitors = []
        self.selected_monitor = None
        self.dragging_monitor = None
        self.drag_start_x = 0
        self.drag_start_y = 0
        self.drag_offset_x = 0
        self.drag_offset_y = 0
        self.scale_factor = 0.1
        self.offset_x = 50
        self.offset_y = 50
        self.has_pending_changes = False

        self.set_draw_func(self.draw)
        self.set_size_request(200, 150)  # Smaller minimum for tiling
        self.set_vexpand(True)
        self.set_hexpand(True)

        # Click handling for selection
        click = Gtk.GestureClick()
        click.connect('pressed', self.on_click)
        self.add_controller(click)

        # Drag handling
        drag = Gtk.GestureDrag()
        drag.connect('drag-begin', self.on_drag_begin)
        drag.connect('drag-update', self.on_drag_update)
        drag.connect('drag-end', self.on_drag_end)
        self.add_controller(drag)

        # Change cursor on hover
        motion = Gtk.EventControllerMotion()
        motion.connect('motion', self.on_motion)
        self.add_controller(motion)

    def set_monitors(self, monitors):
        self.monitors = monitors
        # Reset pending positions
        for m in self.monitors:
            m.pending_x = m.x
            m.pending_y = m.y
        self.has_pending_changes = False
        self._calculate_scale()
        self.queue_draw()

    def set_selected(self, monitor_name):
        self.selected_monitor = monitor_name
        self.queue_draw()

    def _calculate_scale(self):
        """Calculate scale to fit all monitors in view"""
        if not self.monitors:
            return

        # Find bounding box using pending positions
        active_monitors = [m for m in self.monitors if not m.disabled]
        if not active_monitors:
            return

        min_x = min(m.pending_x for m in active_monitors)
        min_y = min(m.pending_y for m in active_monitors)
        max_x = max(m.pending_x + m.get_effective_size()[0] for m in active_monitors)
        max_y = max(m.pending_y + m.get_effective_size()[1] for m in active_monitors)

        total_width = max_x - min_x
        total_height = max_y - min_y

        # Get available space
        width = self.get_width() - 80
        height = self.get_height() - 80

        if width <= 0 or height <= 0:
            width = 370
            height = 220

        # Calculate scale to fit
        scale_x = width / total_width if total_width > 0 else 1
        scale_y = height / total_height if total_height > 0 else 1
        self.scale_factor = min(scale_x, scale_y, 0.12)

        # Center offset
        self.offset_x = (self.get_width() - total_width * self.scale_factor) / 2 - min_x * self.scale_factor
        self.offset_y = (self.get_height() - total_height * self.scale_factor) / 2 - min_y * self.scale_factor

    def _get_monitor_rect(self, monitor):
        """Get screen coordinates for a monitor"""
        eff_w, eff_h = monitor.get_effective_size()
        x = monitor.pending_x * self.scale_factor + self.offset_x
        y = monitor.pending_y * self.scale_factor + self.offset_y
        w = eff_w * self.scale_factor
        h = eff_h * self.scale_factor
        return (x, y, w, h)

    def _get_monitor_at(self, x, y):
        """Get monitor at screen coordinates"""
        for monitor in reversed(self.monitors):  # Check in reverse for top-most
            if monitor.disabled:
                continue
            mx, my, mw, mh = self._get_monitor_rect(monitor)
            if mx <= x <= mx + mw and my <= y <= my + mh:
                return monitor
        return None

    def draw(self, area, cr, width, height):
        # Background
        cr.set_source_rgb(0.16, 0.16, 0.16)  # Gruvbox bg0
        cr.rectangle(0, 0, width, height)
        cr.fill()

        if not self.monitors:
            # Draw hint text
            cr.set_source_rgb(0.5, 0.5, 0.5)
            cr.select_font_face("sans-serif", 0, 0)
            cr.set_font_size(14)
            cr.move_to(width/2 - 80, height/2)
            cr.show_text("No monitors detected")
            return

        self._calculate_scale()

        # Draw monitors (non-selected first, then selected on top)
        for monitor in self.monitors:
            if monitor.disabled or monitor.name == self.selected_monitor:
                continue
            self._draw_monitor(cr, monitor, False)

        # Draw selected monitor last (on top)
        for monitor in self.monitors:
            if monitor.name == self.selected_monitor and not monitor.disabled:
                self._draw_monitor(cr, monitor, True)
                break

        # Draw "pending changes" indicator
        if self.has_pending_changes:
            cr.set_source_rgb(0.98, 0.74, 0.18)  # Gruvbox yellow
            cr.select_font_face("sans-serif", 0, 0)
            cr.set_font_size(11)
            cr.move_to(10, height - 10)
            cr.show_text("⚠ Drag changes pending - click Apply to save")

    def _draw_monitor(self, cr, monitor, is_selected):
        """Draw a single monitor"""
        x, y, w, h = self._get_monitor_rect(monitor)

        # Monitor fill
        if is_selected:
            if self.dragging_monitor == monitor.name:
                cr.set_source_rgba(0.84, 0.6, 0.13, 0.8)  # Semi-transparent when dragging
            else:
                cr.set_source_rgb(0.84, 0.6, 0.13)  # Gruvbox yellow
        else:
            cr.set_source_rgb(0.31, 0.29, 0.27)  # Gruvbox bg2

        cr.rectangle(x, y, w, h)
        cr.fill()

        # Border
        if is_selected:
            cr.set_source_rgb(0.98, 0.74, 0.18)  # Gruvbox bright yellow
            cr.set_line_width(3)
        else:
            cr.set_source_rgb(0.56, 0.75, 0.49)  # Gruvbox green
            cr.set_line_width(2)

        cr.rectangle(x, y, w, h)
        cr.stroke()

        # Monitor name
        cr.set_source_rgb(0.92, 0.86, 0.7)  # Gruvbox fg
        cr.select_font_face("monospace", 0, 0)
        cr.set_font_size(11)

        text = monitor.name
        extents = cr.text_extents(text)
        text_x = x + (w - extents.width) / 2
        text_y = y + (h + extents.height) / 2 - 8

        cr.move_to(text_x, text_y)
        cr.show_text(text)

        # Resolution below name
        cr.set_font_size(9)
        eff_w, eff_h = monitor.get_effective_size()
        res_text = f"{eff_w}x{eff_h}"
        extents = cr.text_extents(res_text)
        cr.move_to(x + (w - extents.width) / 2, text_y + 12)
        cr.show_text(res_text)

        # Position indicator
        cr.set_font_size(8)
        cr.set_source_rgb(0.7, 0.7, 0.7)
        pos_text = f"({monitor.pending_x}, {monitor.pending_y})"
        extents = cr.text_extents(pos_text)
        cr.move_to(x + (w - extents.width) / 2, text_y + 22)
        cr.show_text(pos_text)

    def on_click(self, gesture, n_press, x, y):
        """Handle click to select monitor"""
        monitor = self._get_monitor_at(x, y)
        if monitor:
            self.selected_monitor = monitor.name
            self.queue_draw()
            if self.app:
                self.app.select_monitor(monitor.name)

    def on_drag_begin(self, gesture, start_x, start_y):
        """Start dragging a monitor"""
        monitor = self._get_monitor_at(start_x, start_y)
        if monitor:
            self.dragging_monitor = monitor.name
            self.selected_monitor = monitor.name
            mx, my, _, _ = self._get_monitor_rect(monitor)
            self.drag_offset_x = start_x - mx
            self.drag_offset_y = start_y - my
            self.drag_start_x = monitor.pending_x
            self.drag_start_y = monitor.pending_y
            if self.app:
                self.app.select_monitor(monitor.name)

    def on_drag_update(self, gesture, offset_x, offset_y):
        """Update monitor position while dragging"""
        if not self.dragging_monitor:
            return

        for monitor in self.monitors:
            if monitor.name == self.dragging_monitor:
                # Convert screen offset to monitor coordinates
                new_x = self.drag_start_x + int(offset_x / self.scale_factor)
                new_y = self.drag_start_y + int(offset_y / self.scale_factor)

                # Snap to grid (10 pixel increments)
                snap = 10
                new_x = round(new_x / snap) * snap
                new_y = round(new_y / snap) * snap

                monitor.pending_x = new_x
                monitor.pending_y = new_y
                self.has_pending_changes = True

                # Update the position spinners in real-time
                if self.app:
                    self.app.update_position_from_drag(new_x, new_y)

                self.queue_draw()
                break

    def on_drag_end(self, gesture, offset_x, offset_y):
        """Finish dragging"""
        self.dragging_monitor = None
        self.queue_draw()

    def on_motion(self, controller, x, y):
        """Update cursor based on hover"""
        monitor = self._get_monitor_at(x, y)
        if monitor:
            self.set_cursor(Gdk.Cursor.new_from_name("grab", None))
        else:
            self.set_cursor(None)

    def get_pending_positions(self):
        """Get all pending monitor positions"""
        return {m.name: (m.pending_x, m.pending_y) for m in self.monitors}

    def reset_pending(self):
        """Reset pending positions to actual positions"""
        for m in self.monitors:
            m.pending_x = m.x
            m.pending_y = m.y
        self.has_pending_changes = False
        self.queue_draw()


class MonitorManagerApp(Adw.Application):
    def __init__(self):
        super().__init__(application_id='com.hyprland.monitor-manager')
        self.monitors = []
        self.current_monitor = None
        self.updating_from_drag = False
        self.original_positions = {}  # Store positions when first loaded

    def do_activate(self):
        # Apply Gruvbox-themed CSS
        css_provider = Gtk.CssProvider()
        css_provider.load_from_data(b"""
            * {
                font-family: "JetBrains Mono", "GohuFont", monospace;
                font-size: 11px;
            }
            window {
                background-color: #282828;
                color: #ebdbb2;
            }
            headerbar {
                background-color: #1d2021;
                color: #ebdbb2;
            }
            frame > label {
                color: #fabd2f;
                font-weight: bold;
            }
            button {
                background-color: #3c3836;
                color: #ebdbb2;
                border-color: #504945;
            }
            button:hover {
                background-color: #504945;
            }
            button.suggested-action {
                background-color: #98971a;
                color: #282828;
            }
            entry, spinbutton, combobox {
                background-color: #3c3836;
                color: #ebdbb2;
            }
        """)
        Gtk.StyleContext.add_provider_for_display(
            Gdk.Display.get_default(),
            css_provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        )

        win = Adw.ApplicationWindow(application=self)
        win.set_title("Monitor Manager")
        win.set_default_size(620, 450)

        # Main layout
        main_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)

        # Header bar
        header = Adw.HeaderBar()
        header.set_title_widget(Gtk.Label(label="Monitor Manager"))

        refresh_btn = Gtk.Button(icon_name="view-refresh-symbolic")
        refresh_btn.set_tooltip_text("Refresh")
        refresh_btn.connect('clicked', self.on_refresh)
        header.pack_start(refresh_btn)

        main_box.append(header)

        # Content area
        content = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=6)
        content.set_margin_start(6)
        content.set_margin_end(6)
        content.set_margin_top(6)
        content.set_margin_bottom(6)

        # Left side - preview
        left_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)

        preview_frame = Gtk.Frame()
        preview_frame.set_label("Layout Preview (drag monitors to reposition)")
        self.preview = MonitorPreview(self)
        preview_frame.set_child(self.preview)
        left_box.append(preview_frame)

        left_box.set_hexpand(True)
        left_box.set_vexpand(True)
        content.append(left_box)

        # Right side - settings (scrollable for tiling)
        right_scroll = Gtk.ScrolledWindow()
        right_scroll.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        right_scroll.set_size_request(220, -1)
        right_scroll.set_vexpand(True)

        right_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=6)
        right_box.set_margin_start(2)
        right_box.set_margin_end(2)

        # Presets section
        presets_frame = Gtk.Frame()
        presets_frame.set_label("Presets")

        presets_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
        presets_box.set_margin_start(6)
        presets_box.set_margin_end(6)
        presets_box.set_margin_top(4)
        presets_box.set_margin_bottom(4)

        # Preset selector
        preset_row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=4)
        self.preset_combo = Gtk.ComboBoxText()
        self.preset_combo.set_hexpand(True)
        self.refresh_presets()
        preset_row.append(self.preset_combo)

        load_preset_btn = Gtk.Button(label="Load")
        load_preset_btn.connect('clicked', self.on_load_preset)
        preset_row.append(load_preset_btn)

        delete_preset_btn = Gtk.Button(icon_name="user-trash-symbolic")
        delete_preset_btn.set_tooltip_text("Delete preset")
        delete_preset_btn.connect('clicked', self.on_delete_preset)
        preset_row.append(delete_preset_btn)

        presets_box.append(preset_row)

        # Save new preset
        save_row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=4)
        self.preset_name_entry = Gtk.Entry()
        self.preset_name_entry.set_placeholder_text("New preset name...")
        self.preset_name_entry.set_hexpand(True)
        save_row.append(self.preset_name_entry)

        save_preset_btn = Gtk.Button(label="Save")
        save_preset_btn.add_css_class("suggested-action")
        save_preset_btn.connect('clicked', self.on_save_preset)
        save_row.append(save_preset_btn)

        presets_box.append(save_row)
        presets_frame.set_child(presets_box)
        right_box.append(presets_frame)

        settings_frame = Gtk.Frame()
        settings_frame.set_label("Monitor Settings")

        settings_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
        settings_box.set_margin_start(4)
        settings_box.set_margin_end(4)
        settings_box.set_margin_top(4)
        settings_box.set_margin_bottom(4)

        # Monitor selector
        self.monitor_combo = Gtk.ComboBoxText()
        self.monitor_combo.connect('changed', self.on_monitor_changed)
        settings_box.append(self._create_row("Monitor:", self.monitor_combo))

        # Enable switch
        self.enable_switch = Gtk.Switch()
        self.enable_switch.set_active(True)
        settings_box.append(self._create_row("Enabled:", self.enable_switch))

        # Resolution
        self.resolution_combo = Gtk.ComboBoxText()
        settings_box.append(self._create_row("Resolution:", self.resolution_combo))

        # Refresh rate
        self.rate_combo = Gtk.ComboBoxText()
        settings_box.append(self._create_row("Refresh Rate:", self.rate_combo))

        # Scale
        self.scale_spin = Gtk.SpinButton()
        self.scale_spin.set_adjustment(Gtk.Adjustment(value=1.0, lower=0.5, upper=3.0, step_increment=0.1))
        self.scale_spin.set_digits(2)
        settings_box.append(self._create_row("Scale:", self.scale_spin))

        # Rotation
        self.rotation_combo = Gtk.ComboBoxText()
        for rot in ["Normal", "90°", "180°", "270°"]:
            self.rotation_combo.append_text(rot)
        self.rotation_combo.set_active(0)
        settings_box.append(self._create_row("Rotation:", self.rotation_combo))

        # Position X/Y
        pos_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=2)
        self.pos_x_spin = Gtk.SpinButton()
        self.pos_x_spin.set_adjustment(Gtk.Adjustment(value=0, lower=-10000, upper=10000, step_increment=10))
        self.pos_x_spin.connect('value-changed', self.on_position_spin_changed)
        self.pos_y_spin = Gtk.SpinButton()
        self.pos_y_spin.set_adjustment(Gtk.Adjustment(value=0, lower=-10000, upper=10000, step_increment=10))
        self.pos_y_spin.connect('value-changed', self.on_position_spin_changed)
        pos_box.append(self.pos_x_spin)
        pos_box.append(self.pos_y_spin)
        settings_box.append(self._create_row("Pos X,Y:", pos_box))

        # Mirror
        self.mirror_combo = Gtk.ComboBoxText()
        self.mirror_combo.append_text("None")
        settings_box.append(self._create_row("Mirror:", self.mirror_combo))

        settings_frame.set_child(settings_box)
        right_box.append(settings_frame)

        # Buttons
        btn_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=6)
        btn_box.set_halign(Gtk.Align.END)
        btn_box.set_margin_top(6)
        btn_box.set_margin_bottom(6)

        reset_btn = Gtk.Button(label="Reset")
        reset_btn.connect('clicked', self.on_reset)
        btn_box.append(reset_btn)

        apply_btn = Gtk.Button(label="Apply")
        apply_btn.add_css_class("suggested-action")
        apply_btn.connect('clicked', self.on_apply)
        btn_box.append(apply_btn)

        apply_all_btn = Gtk.Button(label="Apply All")
        apply_all_btn.connect('clicked', self.on_apply_all)
        btn_box.append(apply_all_btn)

        right_box.append(btn_box)

        right_scroll.set_child(right_box)
        content.append(right_scroll)
        main_box.append(content)

        win.set_content(main_box)

        # Load monitors
        self.load_monitors()

        win.present()

    def _create_row(self, label_text, widget):
        """Create a labeled row"""
        box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=4)
        label = Gtk.Label(label=label_text)
        label.set_xalign(0)
        label.set_size_request(65, -1)
        box.append(label)
        widget.set_hexpand(True)
        box.append(widget)
        return box

    def load_monitors(self, save_original=True):
        """Load monitor configuration from hyprctl"""
        try:
            result = subprocess.run(
                ['hyprctl', 'monitors', '-j'],
                capture_output=True, text=True
            )
            data = json.loads(result.stdout)
            self.monitors = [Monitor(m) for m in data]

            # Store original positions on first load or when explicitly requested
            if save_original or not self.original_positions:
                self.original_positions = {m.name: (m.x, m.y) for m in self.monitors}

            # Update UI
            self.monitor_combo.remove_all()
            self.mirror_combo.remove_all()
            self.mirror_combo.append_text("None")

            for m in self.monitors:
                self.monitor_combo.append_text(m.get_display_name())
                self.mirror_combo.append_text(m.name)

            if self.monitors:
                self.monitor_combo.set_active(0)

            self.preview.set_monitors(self.monitors)

        except Exception as e:
            print(f"Error loading monitors: {e}")

    def on_refresh(self, btn):
        self.load_monitors()

    def on_reset(self, btn):
        """Reset to original positions (from when app was opened)"""
        # Reset all monitors to their original positions
        for m in self.monitors:
            if m.name in self.original_positions:
                m.pending_x, m.pending_y = self.original_positions[m.name]
            else:
                m.pending_x, m.pending_y = m.x, m.y

        self.preview.has_pending_changes = False
        self.preview.queue_draw()

        # Update position spinners for current monitor
        if self.current_monitor and self.current_monitor.name in self.original_positions:
            orig_x, orig_y = self.original_positions[self.current_monitor.name]
            self.updating_from_drag = True
            self.pos_x_spin.set_value(orig_x)
            self.pos_y_spin.set_value(orig_y)
            self.updating_from_drag = False

    def on_monitor_changed(self, combo):
        """Update settings panel for selected monitor"""
        idx = combo.get_active()
        if idx < 0 or idx >= len(self.monitors):
            return

        monitor = self.monitors[idx]
        self.current_monitor = monitor

        # Update enable switch
        self.enable_switch.set_active(not monitor.disabled)

        # Update resolution combo
        self.resolution_combo.remove_all()
        resolutions = set()
        for mode in monitor.available_modes:
            res = f"{mode['width']}x{mode['height']}"
            if res not in resolutions:
                resolutions.add(res)
                self.resolution_combo.append_text(res)

        current_res = f"{monitor.width}x{monitor.height}"
        model = self.resolution_combo.get_model()
        for i, row in enumerate(model):
            if row[0] == current_res:
                self.resolution_combo.set_active(i)
                break

        # Update refresh rates
        self.update_refresh_rates()

        # Update scale
        self.scale_spin.set_value(monitor.scale)

        # Update rotation
        rot_map = {0: 0, 1: 1, 2: 2, 3: 3, 4: 0, 5: 1, 6: 2, 7: 3}
        self.rotation_combo.set_active(rot_map.get(monitor.transform, 0))

        # Update position (use pending position if available)
        self.updating_from_drag = True
        self.pos_x_spin.set_value(monitor.pending_x)
        self.pos_y_spin.set_value(monitor.pending_y)
        self.updating_from_drag = False

        # Update preview selection
        self.preview.set_selected(monitor.name)

    def update_refresh_rates(self):
        """Update refresh rate combo for selected resolution"""
        if not self.current_monitor:
            return

        self.rate_combo.remove_all()

        res_text = self.resolution_combo.get_active_text()
        if not res_text:
            return

        try:
            w, h = map(int, res_text.split('x'))
        except:
            return

        rates = set()
        for mode in self.current_monitor.available_modes:
            if mode['width'] == w and mode['height'] == h:
                rate = f"{mode['rate']:.2f}Hz"
                if rate not in rates:
                    rates.add(rate)
                    self.rate_combo.append_text(rate)

        # Select current rate
        current_rate = f"{self.current_monitor.refresh_rate:.2f}Hz"
        model = self.rate_combo.get_model()
        for i, row in enumerate(model):
            if row[0] == current_rate:
                self.rate_combo.set_active(i)
                break
        else:
            if model.iter_n_children(None) > 0:
                self.rate_combo.set_active(0)

    def select_monitor(self, name):
        """Select monitor from preview click"""
        for i, m in enumerate(self.monitors):
            if m.name == name:
                self.monitor_combo.set_active(i)
                break

    def update_position_from_drag(self, x, y):
        """Update position spinners from drag operation"""
        self.updating_from_drag = True
        self.pos_x_spin.set_value(x)
        self.pos_y_spin.set_value(y)
        self.updating_from_drag = False

    def on_position_spin_changed(self, spin):
        """Handle manual position changes in spinners"""
        if self.updating_from_drag or not self.current_monitor:
            return

        # Update the preview when spinners are manually changed
        new_x = int(self.pos_x_spin.get_value())
        new_y = int(self.pos_y_spin.get_value())
        self.current_monitor.pending_x = new_x
        self.current_monitor.pending_y = new_y
        self.preview.has_pending_changes = True
        self.preview.queue_draw()

    def on_apply(self, btn):
        """Apply current monitor settings"""
        if not self.current_monitor:
            return

        mon = self.current_monitor

        if not self.enable_switch.get_active():
            cmd = ["hyprctl", "keyword", "monitor", f"{mon.name},disable"]
        else:
            scale = self.scale_spin.get_value()
            x = int(self.pos_x_spin.get_value())
            y = int(self.pos_y_spin.get_value())

            rot_idx = self.rotation_combo.get_active()
            transform = [0, 1, 2, 3][rot_idx] if rot_idx >= 0 else 0

            mirror_idx = self.mirror_combo.get_active()
            mirror = ""
            if mirror_idx > 0:
                mirror_name = self.mirror_combo.get_active_text()
                mirror = f",mirror,{mirror_name}"

            # Use preferred to let Hyprland pick resolution/rate
            monitor_str = f"{mon.name},preferred,{x}x{y},{scale},transform,{transform}{mirror}"
            cmd = ["hyprctl", "keyword", "monitor", monitor_str]

        try:
            result = subprocess.run(cmd, capture_output=True, text=True)
            if result.returncode == 0:
                self.send_notification("Applied", mon.name)
            else:
                self.send_notification("Error", result.stderr or "Unknown error")
            # Reload but don't overwrite original positions
            GLib.timeout_add(500, lambda: self.load_monitors(save_original=False))
        except Exception as e:
            self.send_notification("Error", str(e))

    def on_apply_all(self, btn):
        """Apply all pending monitor positions"""
        positions = self.preview.get_pending_positions()
        errors = []

        for mon in self.monitors:
            if mon.disabled:
                continue

            x, y = positions.get(mon.name, (mon.x, mon.y))
            scale = mon.scale
            transform = mon.transform

            monitor_str = f"{mon.name},preferred,{x}x{y},{scale},transform,{transform}"
            cmd = ["hyprctl", "keyword", "monitor", monitor_str]

            try:
                result = subprocess.run(cmd, capture_output=True, text=True)
                if result.returncode != 0:
                    errors.append(f"{mon.name}: {result.stderr}")
            except Exception as e:
                errors.append(f"{mon.name}: {e}")

        if errors:
            self.send_notification("Errors", "\n".join(errors))
        else:
            self.send_notification("Applied", "All monitors updated")

        # Reload but don't overwrite original positions
        GLib.timeout_add(500, lambda: self.load_monitors(save_original=False))

    def send_notification(self, title, message):
        """Send desktop notification"""
        try:
            subprocess.run(['notify-send', title, message, '-t', '2000'])
        except:
            pass

    def refresh_presets(self):
        """Refresh the preset dropdown"""
        self.preset_combo.remove_all()
        for preset in get_presets():
            self.preset_combo.append_text(preset)
        if self.preset_combo.get_model().iter_n_children(None) > 0:
            self.preset_combo.set_active(0)

    def on_save_preset(self, btn):
        """Save current configuration as a preset"""
        name = self.preset_name_entry.get_text().strip()
        if not name:
            self.send_notification("Error", "Please enter a preset name")
            return

        # Sanitize name (remove invalid filename characters)
        safe_name = "".join(c for c in name if c.isalnum() or c in " -_").strip()
        if not safe_name:
            self.send_notification("Error", "Invalid preset name")
            return

        if save_preset(safe_name, self.monitors):
            self.send_notification("Preset Saved", f"'{safe_name}' saved successfully")
            self.preset_name_entry.set_text("")
            self.refresh_presets()
            # Select the newly saved preset
            model = self.preset_combo.get_model()
            for i, row in enumerate(model):
                if row[0] == safe_name:
                    self.preset_combo.set_active(i)
                    break

    def on_load_preset(self, btn):
        """Load selected preset"""
        preset_name = self.preset_combo.get_active_text()
        if not preset_name:
            self.send_notification("Error", "No preset selected")
            return

        preset_data = load_preset(preset_name)
        if not preset_data:
            self.send_notification("Error", f"Could not load preset '{preset_name}'")
            return

        # Apply preset to all monitors
        errors = []
        for preset_mon in preset_data.get("monitors", []):
            mon_name = preset_mon["name"]
            x = preset_mon.get("x", 0)
            y = preset_mon.get("y", 0)
            scale = preset_mon.get("scale", 1)
            transform = preset_mon.get("transform", 0)
            disabled = preset_mon.get("disabled", False)

            if disabled:
                cmd = ["hyprctl", "keyword", "monitor", f"{mon_name},disable"]
            else:
                monitor_str = f"{mon_name},preferred,{x}x{y},{scale},transform,{transform}"
                cmd = ["hyprctl", "keyword", "monitor", monitor_str]

            try:
                result = subprocess.run(cmd, capture_output=True, text=True)
                if result.returncode != 0:
                    errors.append(f"{mon_name}: {result.stderr}")
            except Exception as e:
                errors.append(f"{mon_name}: {e}")

        if errors:
            self.send_notification("Errors", "\n".join(errors))
        else:
            self.send_notification("Preset Loaded", f"'{preset_name}' applied")

        # Reload monitors
        GLib.timeout_add(500, lambda: self.load_monitors(save_original=False))

    def on_delete_preset(self, btn):
        """Delete selected preset"""
        preset_name = self.preset_combo.get_active_text()
        if not preset_name:
            self.send_notification("Error", "No preset selected")
            return

        if delete_preset(preset_name):
            self.send_notification("Preset Deleted", f"'{preset_name}' deleted")
            self.refresh_presets()
        else:
            self.send_notification("Error", f"Could not delete '{preset_name}'")


def main():
    app = MonitorManagerApp()
    app.run(None)


if __name__ == '__main__':
    main()
