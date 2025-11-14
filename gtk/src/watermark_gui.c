/* watermark_gui.c
 *
 * GTK GUI for watermark editor with drag & drop support
 */

#include <gtk/gtk.h>
#include <cairo.h>
#include <string.h>
#include "watermark_extended.h"

typedef struct {
    GtkWidget *window;
    GtkWidget *notebook;
    
    // Type selection
    GtkWidget *type_radio_none;
    GtkWidget *type_radio_image;
    GtkWidget *type_radio_text;
    
    // Image watermark widgets
    GtkWidget *image_file_chooser;
    GtkWidget *image_width_spin;
    GtkWidget *image_height_spin;
    GtkWidget *image_preview;
    
    // Text watermark widgets
    GtkWidget *text_entry;
    GtkWidget *font_button;
    GtkWidget *font_size_spin;
    GtkWidget *text_color_button;
    GtkWidget *text_bold_check;
    GtkWidget *text_italic_check;
    GtkWidget *outline_color_button;
    GtkWidget *outline_width_spin;
    
    // Position widgets
    GtkWidget *position_combo;
    GtkWidget *position_x_spin;
    GtkWidget *position_y_spin;
    GtkWidget *use_percentage_check;
    GtkWidget *margin_x_spin;
    GtkWidget *margin_y_spin;
    
    // Position canvas (drag & drop)
    GtkWidget *position_canvas;
    GdkPixbuf *video_preview_pixbuf;
    int canvas_width;
    int canvas_height;
    int watermark_x;
    int watermark_y;
    int watermark_width;
    int watermark_height;
    gboolean dragging;
    
    // Appearance widgets
    GtkWidget *opacity_scale;
    GtkWidget *rotation_spin;
    
    // Preview
    GtkWidget *preview_drawing_area;
    
    watermark_extended_t *current_watermark;
    int video_width;
    int video_height;
} WatermarkGUI;

static void update_preview(WatermarkGUI *gui);

static void on_type_changed(GtkToggleButton *button, gpointer user_data) {
    WatermarkGUI *gui = (WatermarkGUI*)user_data;
    
    if (gtk_toggle_button_get_active(GTK_TOGGLE_BUTTON(gui->type_radio_none))) {
        gui->current_watermark->type = WATERMARK_TYPE_NONE;
    } else if (gtk_toggle_button_get_active(GTK_TOGGLE_BUTTON(gui->type_radio_image))) {
        gui->current_watermark->type = WATERMARK_TYPE_IMAGE;
    } else if (gtk_toggle_button_get_active(GTK_TOGGLE_BUTTON(gui->type_radio_text))) {
        gui->current_watermark->type = WATERMARK_TYPE_TEXT;
    }
    
    update_preview(gui);
}

static void on_image_file_set(GtkFileChooserButton *button, gpointer user_data) {
    WatermarkGUI *gui = (WatermarkGUI*)user_data;
    char *filename = gtk_file_chooser_get_filename(GTK_FILE_CHOOSER(button));
    
    if (filename) {
        watermark_set_image(gui->current_watermark, filename);
        
        // Load preview
        GError *error = NULL;
        GdkPixbuf *pixbuf = gdk_pixbuf_new_from_file_at_scale(filename, 200, 200, TRUE, &error);
        if (pixbuf) {
            gtk_image_set_from_pixbuf(GTK_IMAGE(gui->image_preview), pixbuf);
            g_object_unref(pixbuf);
        }
        
        g_free(filename);
        update_preview(gui);
    }
}

static void on_text_changed(GtkEntry *entry, gpointer user_data) {
    WatermarkGUI *gui = (WatermarkGUI*)user_data;
    const char *text = gtk_entry_get_text(entry);
    watermark_set_text(gui->current_watermark, text);
    update_preview(gui);
}

static void on_position_x_changed(GtkSpinButton *spin, gpointer user_data) {
    WatermarkGUI *gui = (WatermarkGUI*)user_data;
    gui->current_watermark->position_x = gtk_spin_button_get_value_as_int(spin);
    update_preview(gui);
}

static void on_position_y_changed(GtkSpinButton *spin, gpointer user_data) {
    WatermarkGUI *gui = (WatermarkGUI*)user_data;
    gui->current_watermark->position_y = gtk_spin_button_get_value_as_int(spin);
    update_preview(gui);
}

static void on_position_preset_changed(GtkComboBox *combo, gpointer user_data) {
    WatermarkGUI *gui = (WatermarkGUI*)user_data;
    int active = gtk_combo_box_get_active(combo);
    gui->current_watermark->position_preset = active;
    update_preview(gui);
}

static void on_opacity_changed(GtkRange *range, gpointer user_data) {
    WatermarkGUI *gui = (WatermarkGUI*)user_data;
    gui->current_watermark->opacity = (int)gtk_range_get_value(range);
    update_preview(gui);
}

// Drag & Drop canvas
static gboolean on_canvas_draw(GtkWidget *widget, cairo_t *cr, gpointer user_data) {
    WatermarkGUI *gui = (WatermarkGUI*)user_data;
    
    int width = gtk_widget_get_allocated_width(widget);
    int height = gtk_widget_get_allocated_height(widget);
    
    // Draw video preview background (dark gray)
    cairo_set_source_rgb(cr, 0.2, 0.2, 0.2);
    cairo_rectangle(cr, 0, 0, width, height);
    cairo_fill(cr);
    
    // Draw grid
    cairo_set_source_rgb(cr, 0.3, 0.3, 0.3);
    cairo_set_line_width(cr, 1.0);
    for (int i = 0; i < width; i += 40) {
        cairo_move_to(cr, i, 0);
        cairo_line_to(cr, i, height);
    }
    for (int i = 0; i < height; i += 40) {
        cairo_move_to(cr, 0, i);
        cairo_line_to(cr, width, i);
    }
    cairo_stroke(cr);
    
    // Draw watermark position indicator
    if (gui->current_watermark->type != WATERMARK_TYPE_NONE) {
        double alpha = gui->current_watermark->opacity / 100.0;
        
        // Calculate position based on current settings
        int x = gui->watermark_x;
        int y = gui->watermark_y;
        int w = gui->watermark_width;
        int h = gui->watermark_height;
        
        if (gui->current_watermark->type == WATERMARK_TYPE_IMAGE) {
            // Draw image placeholder
            cairo_set_source_rgba(cr, 0.5, 0.5, 1.0, alpha);
            cairo_rectangle(cr, x, y, w, h);
            cairo_fill(cr);
            
            // Border
            cairo_set_source_rgb(cr, 1.0, 1.0, 1.0);
            cairo_set_line_width(cr, 2.0);
            cairo_rectangle(cr, x, y, w, h);
            cairo_stroke(cr);
            
            // Draw "IMG" text
            cairo_set_source_rgb(cr, 1.0, 1.0, 1.0);
            cairo_select_font_face(cr, "Sans", CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_BOLD);
            cairo_set_font_size(cr, 16);
            cairo_move_to(cr, x + w/2 - 15, y + h/2 + 5);
            cairo_show_text(cr, "IMG");
            
        } else if (gui->current_watermark->type == WATERMARK_TYPE_TEXT) {
            // Draw text watermark
            cairo_set_source_rgba(cr, 1.0, 1.0, 1.0, alpha);
            cairo_select_font_face(cr, "Sans", CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_NORMAL);
            cairo_set_font_size(cr, 14);
            cairo_move_to(cr, x, y + 14);
            cairo_show_text(cr, gui->current_watermark->text ? gui->current_watermark->text : "Text");
            
            // Border around text area
            cairo_set_source_rgb(cr, 1.0, 1.0, 0.0);
            cairo_set_line_width(cr, 1.0);
            cairo_rectangle(cr, x - 2, y - 2, w + 4, h + 4);
            cairo_stroke(cr);
        }
        
        // Draw corner handles for resizing
        cairo_set_source_rgb(cr, 1.0, 0.0, 0.0);
        cairo_arc(cr, x, y, 4, 0, 2 * G_PI);
        cairo_fill(cr);
        cairo_arc(cr, x + w, y, 4, 0, 2 * G_PI);
        cairo_fill(cr);
        cairo_arc(cr, x, y + h, 4, 0, 2 * G_PI);
        cairo_fill(cr);
        cairo_arc(cr, x + w, y + h, 4, 0, 2 * G_PI);
        cairo_fill(cr);
    }
    
    // Draw position coordinates
    char pos_text[128];
    snprintf(pos_text, sizeof(pos_text), "Position: %d, %d | Size: %d × %d", 
             gui->watermark_x, gui->watermark_y, gui->watermark_width, gui->watermark_height);
    
    cairo_set_source_rgb(cr, 1.0, 1.0, 1.0);
    cairo_select_font_face(cr, "Sans", CAIRO_FONT_SLANT_NORMAL, CAIRO_FONT_WEIGHT_NORMAL);
    cairo_set_font_size(cr, 12);
    cairo_move_to(cr, 5, height - 5);
    cairo_show_text(cr, pos_text);
    
    return FALSE;
}

static gboolean on_canvas_button_press(GtkWidget *widget, GdkEventButton *event, gpointer user_data) {
    WatermarkGUI *gui = (WatermarkGUI*)user_data;
    
    // Check if click is inside watermark area
    if (event->x >= gui->watermark_x && event->x <= gui->watermark_x + gui->watermark_width &&
        event->y >= gui->watermark_y && event->y <= gui->watermark_y + gui->watermark_height) {
        gui->dragging = TRUE;
        return TRUE;
    }
    
    return FALSE;
}

static gboolean on_canvas_button_release(GtkWidget *widget, GdkEventButton *event, gpointer user_data) {
    WatermarkGUI *gui = (WatermarkGUI*)user_data;
    gui->dragging = FALSE;
    
    // Update spin buttons with new position
    gtk_spin_button_set_value(GTK_SPIN_BUTTON(gui->position_x_spin), gui->watermark_x);
    gtk_spin_button_set_value(GTK_SPIN_BUTTON(gui->position_y_spin), gui->watermark_y);
    
    return TRUE;
}

static gboolean on_canvas_motion(GtkWidget *widget, GdkEventMotion *event, gpointer user_data) {
    WatermarkGUI *gui = (WatermarkGUI*)user_data;
    
    if (gui->dragging) {
        // Update watermark position
        gui->watermark_x = (int)event->x - gui->watermark_width / 2;
        gui->watermark_y = (int)event->y - gui->watermark_height / 2;
        
        // Clamp to canvas bounds
        if (gui->watermark_x < 0) gui->watermark_x = 0;
        if (gui->watermark_y < 0) gui->watermark_y = 0;
        
        int canvas_width = gtk_widget_get_allocated_width(widget);
        int canvas_height = gtk_widget_get_allocated_height(widget);
        
        if (gui->watermark_x + gui->watermark_width > canvas_width)
            gui->watermark_x = canvas_width - gui->watermark_width;
        if (gui->watermark_y + gui->watermark_height > canvas_height)
            gui->watermark_y = canvas_height - gui->watermark_height;
        
        gtk_widget_queue_draw(widget);
        return TRUE;
    }
    
    return FALSE;
}

static void update_preview(WatermarkGUI *gui) {
    if (gui->position_canvas) {
        gtk_widget_queue_draw(gui->position_canvas);
    }
}

static GtkWidget* create_type_selection_tab(WatermarkGUI *gui) {
    GtkWidget *vbox = gtk_box_new(GTK_ORIENTATION_VERTICAL, 10);
    gtk_container_set_border_width(GTK_CONTAINER(vbox), 10);
    
    GtkWidget *label = gtk_label_new(NULL);
    gtk_label_set_markup(GTK_LABEL(label), "<b>Select Watermark Type:</b>");
    gtk_widget_set_halign(label, GTK_ALIGN_START);
    gtk_box_pack_start(GTK_BOX(vbox), label, FALSE, FALSE, 0);
    
    gui->type_radio_none = gtk_radio_button_new_with_label(NULL, "No Watermark");
    g_signal_connect(gui->type_radio_none, "toggled", G_CALLBACK(on_type_changed), gui);
    gtk_box_pack_start(GTK_BOX(vbox), gui->type_radio_none, FALSE, FALSE, 0);
    
    gui->type_radio_image = gtk_radio_button_new_with_label_from_widget(
        GTK_RADIO_BUTTON(gui->type_radio_none), "Image Watermark (PNG, JPG)");
    g_signal_connect(gui->type_radio_image, "toggled", G_CALLBACK(on_type_changed), gui);
    gtk_box_pack_start(GTK_BOX(vbox), gui->type_radio_image, FALSE, FALSE, 0);
    
    gui->type_radio_text = gtk_radio_button_new_with_label_from_widget(
        GTK_RADIO_BUTTON(gui->type_radio_none), "Text Watermark");
    g_signal_connect(gui->type_radio_text, "toggled", G_CALLBACK(on_type_changed), gui);
    gtk_box_pack_start(GTK_BOX(vbox), gui->type_radio_text, FALSE, FALSE, 0);
    
    return vbox;
}

static GtkWidget* create_image_tab(WatermarkGUI *gui) {
    GtkWidget *grid = gtk_grid_new();
    gtk_grid_set_row_spacing(GTK_GRID(grid), 10);
    gtk_grid_set_column_spacing(GTK_GRID(grid), 10);
    gtk_container_set_border_width(GTK_CONTAINER(grid), 10);
    
    // Image file chooser
    GtkWidget *file_label = gtk_label_new("Image File:");
    gtk_widget_set_halign(file_label, GTK_ALIGN_START);
    gui->image_file_chooser = gtk_file_chooser_button_new("Select Image", GTK_FILE_CHOOSER_ACTION_OPEN);
    
    GtkFileFilter *filter = gtk_file_filter_new();
    gtk_file_filter_set_name(filter, "Images");
    gtk_file_filter_add_pattern(filter, "*.png");
    gtk_file_filter_add_pattern(filter, "*.jpg");
    gtk_file_filter_add_pattern(filter, "*.jpeg");
    gtk_file_filter_add_pattern(filter, "*.gif");
    gtk_file_chooser_add_filter(GTK_FILE_CHOOSER(gui->image_file_chooser), filter);
    
    g_signal_connect(gui->image_file_chooser, "file-set", G_CALLBACK(on_image_file_set), gui);
    
    gtk_grid_attach(GTK_GRID(grid), file_label, 0, 0, 1, 1);
    gtk_grid_attach(GTK_GRID(grid), gui->image_file_chooser, 1, 0, 2, 1);
    
    // Image size
    GtkWidget *width_label = gtk_label_new("Width (0=auto):");
    gtk_widget_set_halign(width_label, GTK_ALIGN_START);
    gui->image_width_spin = gtk_spin_button_new_with_range(0, 1920, 10);
    gtk_spin_button_set_value(GTK_SPIN_BUTTON(gui->image_width_spin), 0);
    gtk_grid_attach(GTK_GRID(grid), width_label, 0, 1, 1, 1);
    gtk_grid_attach(GTK_GRID(grid), gui->image_width_spin, 1, 1, 2, 1);
    
    GtkWidget *height_label = gtk_label_new("Height (0=auto):");
    gtk_widget_set_halign(height_label, GTK_ALIGN_START);
    gui->image_height_spin = gtk_spin_button_new_with_range(0, 1080, 10);
    gtk_spin_button_set_value(GTK_SPIN_BUTTON(gui->image_height_spin), 0);
    gtk_grid_attach(GTK_GRID(grid), height_label, 0, 2, 1, 1);
    gtk_grid_attach(GTK_GRID(grid), gui->image_height_spin, 1, 2, 2, 1);
    
    // Preview
    GtkWidget *preview_label = gtk_label_new("Preview:");
    gtk_widget_set_halign(preview_label, GTK_ALIGN_START);
    gtk_grid_attach(GTK_GRID(grid), preview_label, 0, 3, 3, 1);
    
    gui->image_preview = gtk_image_new();
    gtk_widget_set_size_request(gui->image_preview, 200, 200);
    gtk_grid_attach(GTK_GRID(grid), gui->image_preview, 0, 4, 3, 1);
    
    return grid;
}

static GtkWidget* create_text_tab(WatermarkGUI *gui) {
    GtkWidget *grid = gtk_grid_new();
    gtk_grid_set_row_spacing(GTK_GRID(grid), 10);
    gtk_grid_set_column_spacing(GTK_GRID(grid), 10);
    gtk_container_set_border_width(GTK_CONTAINER(grid), 10);
    
    // Text entry
    GtkWidget *text_label = gtk_label_new("Text:");
    gtk_widget_set_halign(text_label, GTK_ALIGN_START);
    gui->text_entry = gtk_entry_new();
    gtk_entry_set_text(GTK_ENTRY(gui->text_entry), "K.jpg");
    gtk_entry_set_placeholder_text(GTK_ENTRY(gui->text_entry), "Enter watermark text...");
    g_signal_connect(gui->text_entry, "changed", G_CALLBACK(on_text_changed), gui);
    gtk_grid_attach(GTK_GRID(grid), text_label, 0, 0, 1, 1);
    gtk_grid_attach(GTK_GRID(grid), gui->text_entry, 1, 0, 2, 1);
    
    // Font
    GtkWidget *font_label = gtk_label_new("Font:");
    gtk_widget_set_halign(font_label, GTK_ALIGN_START);
    gui->font_button = gtk_font_button_new();
    gtk_grid_attach(GTK_GRID(grid), font_label, 0, 1, 1, 1);
    gtk_grid_attach(GTK_GRID(grid), gui->font_button, 1, 1, 2, 1);
    
    // Font size
    GtkWidget *size_label = gtk_label_new("Font Size:");
    gtk_widget_set_halign(size_label, GTK_ALIGN_START);
    gui->font_size_spin = gtk_spin_button_new_with_range(8, 200, 1);
    gtk_spin_button_set_value(GTK_SPIN_BUTTON(gui->font_size_spin), 24);
    gtk_grid_attach(GTK_GRID(grid), size_label, 0, 2, 1, 1);
    gtk_grid_attach(GTK_GRID(grid), gui->font_size_spin, 1, 2, 2, 1);
    
    // Text color
    GtkWidget *color_label = gtk_label_new("Text Color:");
    gtk_widget_set_halign(color_label, GTK_ALIGN_START);
    gui->text_color_button = gtk_color_button_new();
    GdkRGBA white = {1.0, 1.0, 1.0, 1.0};
    gtk_color_chooser_set_rgba(GTK_COLOR_CHOOSER(gui->text_color_button), &white);
    gtk_grid_attach(GTK_GRID(grid), color_label, 0, 3, 1, 1);
    gtk_grid_attach(GTK_GRID(grid), gui->text_color_button, 1, 3, 1, 1);
    
    // Style
    gui->text_bold_check = gtk_check_button_new_with_label("Bold");
    gui->text_italic_check = gtk_check_button_new_with_label("Italic");
    gtk_grid_attach(GTK_GRID(grid), gui->text_bold_check, 0, 4, 1, 1);
    gtk_grid_attach(GTK_GRID(grid), gui->text_italic_check, 1, 4, 1, 1);
    
    // Outline
    GtkWidget *outline_label = gtk_label_new("Outline Color:");
    gtk_widget_set_halign(outline_label, GTK_ALIGN_START);
    gui->outline_color_button = gtk_color_button_new();
    GdkRGBA black = {0.0, 0.0, 0.0, 1.0};
    gtk_color_chooser_set_rgba(GTK_COLOR_CHOOSER(gui->outline_color_button), &black);
    gtk_grid_attach(GTK_GRID(grid), outline_label, 0, 5, 1, 1);
    gtk_grid_attach(GTK_GRID(grid), gui->outline_color_button, 1, 5, 1, 1);
    
    GtkWidget *outline_width_label = gtk_label_new("Outline Width:");
    gtk_widget_set_halign(outline_width_label, GTK_ALIGN_START);
    gui->outline_width_spin = gtk_spin_button_new_with_range(0, 10, 1);
    gtk_spin_button_set_value(GTK_SPIN_BUTTON(gui->outline_width_spin), 2);
    gtk_grid_attach(GTK_GRID(grid), outline_width_label, 0, 6, 1, 1);
    gtk_grid_attach(GTK_GRID(grid), gui->outline_width_spin, 1, 6, 2, 1);
    
    return grid;
}

static GtkWidget* create_position_tab(WatermarkGUI *gui) {
    GtkWidget *vbox = gtk_box_new(GTK_ORIENTATION_VERTICAL, 10);
    gtk_container_set_border_width(GTK_CONTAINER(vbox), 10);
    
    // Position presets
    GtkWidget *preset_label = gtk_label_new("Position Preset:");
    gtk_widget_set_halign(preset_label, GTK_ALIGN_START);
    gui->position_combo = gtk_combo_box_text_new();
    gtk_combo_box_text_append_text(GTK_COMBO_BOX_TEXT(gui->position_combo), "Custom");
    gtk_combo_box_text_append_text(GTK_COMBO_BOX_TEXT(gui->position_combo), "Top Left");
    gtk_combo_box_text_append_text(GTK_COMBO_BOX_TEXT(gui->position_combo), "Top Center");
    gtk_combo_box_text_append_text(GTK_COMBO_BOX_TEXT(gui->position_combo), "Top Right");
    gtk_combo_box_text_append_text(GTK_COMBO_BOX_TEXT(gui->position_combo), "Middle Left");
    gtk_combo_box_text_append_text(GTK_COMBO_BOX_TEXT(gui->position_combo), "Middle Center");
    gtk_combo_box_text_append_text(GTK_COMBO_BOX_TEXT(gui->position_combo), "Middle Right");
    gtk_combo_box_text_append_text(GTK_COMBO_BOX_TEXT(gui->position_combo), "Bottom Left");
    gtk_combo_box_text_append_text(GTK_COMBO_BOX_TEXT(gui->position_combo), "Bottom Center");
    gtk_combo_box_text_append_text(GTK_COMBO_BOX_TEXT(gui->position_combo), "Bottom Right");
    gtk_combo_box_set_active(GTK_COMBO_BOX(gui->position_combo), 9);  // Bottom Right default
    g_signal_connect(gui->position_combo, "changed", G_CALLBACK(on_position_preset_changed), gui);
    
    gtk_box_pack_start(GTK_BOX(vbox), preset_label, FALSE, FALSE, 0);
    gtk_box_pack_start(GTK_BOX(vbox), gui->position_combo, FALSE, FALSE, 0);
    
    // Custom position
    GtkWidget *grid = gtk_grid_new();
    gtk_grid_set_row_spacing(GTK_GRID(grid), 10);
    gtk_grid_set_column_spacing(GTK_GRID(grid), 10);
    
    GtkWidget *x_label = gtk_label_new("X Location:");
    gtk_widget_set_halign(x_label, GTK_ALIGN_START);
    gui->position_x_spin = gtk_spin_button_new_with_range(0, 1920, 1);
    gtk_spin_button_set_value(GTK_SPIN_BUTTON(gui->position_x_spin), 320);
    g_signal_connect(gui->position_x_spin, "value-changed", G_CALLBACK(on_position_x_changed), gui);
    gtk_grid_attach(GTK_GRID(grid), x_label, 0, 0, 1, 1);
    gtk_grid_attach(GTK_GRID(grid), gui->position_x_spin, 1, 0, 1, 1);
    
    GtkWidget *y_label = gtk_label_new("Y Location:");
    gtk_widget_set_halign(y_label, GTK_ALIGN_START);
    gui->position_y_spin = gtk_spin_button_new_with_range(0, 1080, 1);
    gtk_spin_button_set_value(GTK_SPIN_BUTTON(gui->position_y_spin), 180);
    g_signal_connect(gui->position_y_spin, "value-changed", G_CALLBACK(on_position_y_changed), gui);
    gtk_grid_attach(GTK_GRID(grid), y_label, 0, 1, 1, 1);
    gtk_grid_attach(GTK_GRID(grid), gui->position_y_spin, 1, 1, 1, 1);
    
    gui->use_percentage_check = gtk_check_button_new_with_label("Use Percentage (0-100%)");
    gtk_toggle_button_set_active(GTK_TOGGLE_BUTTON(gui->use_percentage_check), FALSE);
    gtk_grid_attach(GTK_GRID(grid), gui->use_percentage_check, 0, 2, 2, 1);
    
    gtk_box_pack_start(GTK_BOX(vbox), grid, FALSE, FALSE, 0);
    
    // Drag & Drop Canvas
    GtkWidget *canvas_label = gtk_label_new(NULL);
    gtk_label_set_markup(GTK_LABEL(canvas_label), "<b>Drag & Drop Positioning:</b>");
    gtk_widget_set_halign(canvas_label, GTK_ALIGN_START);
    gtk_box_pack_start(GTK_BOX(vbox), canvas_label, FALSE, FALSE, 5);
    
    gui->position_canvas = gtk_drawing_area_new();
    gtk_widget_set_size_request(gui->position_canvas, 640, 360);
    gtk_widget_add_events(gui->position_canvas, 
                         GDK_BUTTON_PRESS_MASK | 
                         GDK_BUTTON_RELEASE_MASK | 
                         GDK_POINTER_MOTION_MASK);
    
    g_signal_connect(gui->position_canvas, "draw", G_CALLBACK(on_canvas_draw), gui);
    g_signal_connect(gui->position_canvas, "button-press-event", G_CALLBACK(on_canvas_button_press), gui);
    g_signal_connect(gui->position_canvas, "button-release-event", G_CALLBACK(on_canvas_button_release), gui);
    g_signal_connect(gui->position_canvas, "motion-notify-event", G_CALLBACK(on_canvas_motion), gui);
    
    // Initialize watermark position
    gui->watermark_x = 320;
    gui->watermark_y = 180;
    gui->watermark_width = 640 / 10;  // 10% of canvas width
    gui->watermark_height = 360 / 10; // 10% of canvas height
    gui->dragging = FALSE;
    
    GtkWidget *canvas_frame = gtk_frame_new(NULL);
    gtk_container_add(GTK_CONTAINER(canvas_frame), gui->position_canvas);
    gtk_box_pack_start(GTK_BOX(vbox), canvas_frame, TRUE, TRUE, 0);
    
    return vbox;
}

static GtkWidget* create_appearance_tab(WatermarkGUI *gui) {
    GtkWidget *grid = gtk_grid_new();
    gtk_grid_set_row_spacing(GTK_GRID(grid), 10);
    gtk_grid_set_column_spacing(GTK_GRID(grid), 10);
    gtk_container_set_border_width(GTK_CONTAINER(grid), 10);
    
    // Opacity
    GtkWidget *opacity_label = gtk_label_new("Transparency (0-100):");
    gtk_widget_set_halign(opacity_label, GTK_ALIGN_START);
    gui->opacity_scale = gtk_scale_new_with_range(GTK_ORIENTATION_HORIZONTAL, 0, 100, 1);
    gtk_range_set_value(GTK_RANGE(gui->opacity_scale), 70);
    gtk_scale_set_draw_value(GTK_SCALE(gui->opacity_scale), TRUE);
    gtk_scale_set_value_pos(GTK_SCALE(gui->opacity_scale), GTK_POS_RIGHT);
    g_signal_connect(gui->opacity_scale, "value-changed", G_CALLBACK(on_opacity_changed), gui);
    gtk_grid_attach(GTK_GRID(grid), opacity_label, 0, 0, 1, 1);
    gtk_grid_attach(GTK_GRID(grid), gui->opacity_scale, 1, 0, 2, 1);
    
    // Rotation
    GtkWidget *rotation_label = gtk_label_new("Rotation (degrees):");
    gtk_widget_set_halign(rotation_label, GTK_ALIGN_START);
    gui->rotation_spin = gtk_spin_button_new_with_range(-180, 180, 1);
    gtk_spin_button_set_value(GTK_SPIN_BUTTON(gui->rotation_spin), 0);
    gtk_grid_attach(GTK_GRID(grid), rotation_label, 0, 1, 1, 1);
    gtk_grid_attach(GTK_GRID(grid), gui->rotation_spin, 1, 1, 2, 1);
    
    // Size display (matching the screenshot)
    GtkWidget *size_label = gtk_label_new("Size:");
    gtk_widget_set_halign(size_label, GTK_ALIGN_START);
    
    GtkWidget *width_spin = gtk_spin_button_new_with_range(0, 1920, 1);
    gtk_spin_button_set_value(GTK_SPIN_BUTTON(width_spin), 640);
    
    GtkWidget *height_spin = gtk_spin_button_new_with_range(0, 1080, 1);
    gtk_spin_button_set_value(GTK_SPIN_BUTTON(height_spin), 359);
    
    GtkWidget *x_label = gtk_label_new("×");
    
    gtk_grid_attach(GTK_GRID(grid), size_label, 0, 2, 1, 1);
    gtk_grid_attach(GTK_GRID(grid), width_spin, 1, 2, 1, 1);
    gtk_grid_attach(GTK_GRID(grid), x_label, 2, 2, 1, 1);
    gtk_grid_attach(GTK_GRID(grid), height_spin, 3, 2, 1, 1);
    
    return grid;
}

WatermarkGUI* watermark_gui_create() {
    WatermarkGUI *gui = malloc(sizeof(WatermarkGUI));
    if (!gui) return NULL;
    
    gui->current_watermark = watermark_create();
    gui->video_width = 1920;
    gui->video_height = 1080;
    
    // Create main window
    gui->window = gtk_window_new(GTK_WINDOW_TOPLEVEL);
    gtk_window_set_title(GTK_WINDOW(gui->window), "Watermark Editor");
    gtk_window_set_default_size(GTK_WINDOW(gui->window), 700, 700);
    
    // Create notebook
    gui->notebook = gtk_notebook_new();
    
    // Add tabs
    gtk_notebook_append_page(GTK_NOTEBOOK(gui->notebook),
                            create_type_selection_tab(gui),
                            gtk_label_new("Type"));
    
    gtk_notebook_append_page(GTK_NOTEBOOK(gui->notebook),
                            create_image_tab(gui),
                            gtk_label_new("Image"));
    
    gtk_notebook_append_page(GTK_NOTEBOOK(gui->notebook),
                            create_text_tab(gui),
                            gtk_label_new("Text"));
    
    gtk_notebook_append_page(GTK_NOTEBOOK(gui->notebook),
                            create_position_tab(gui),
                            gtk_label_new("Position"));
    
    gtk_notebook_append_page(GTK_NOTEBOOK(gui->notebook),
                            create_appearance_tab(gui),
                            gtk_label_new("Appearance"));
    
    // Buttons
    GtkWidget *vbox = gtk_box_new(GTK_ORIENTATION_VERTICAL, 5);
    gtk_box_pack_start(GTK_BOX(vbox), gui->notebook, TRUE, TRUE, 0);
    
    GtkWidget *button_box = gtk_button_box_new(GTK_ORIENTATION_HORIZONTAL);
    gtk_button_box_set_layout(GTK_BUTTON_BOX(button_box), GTK_BUTTONBOX_END);
    
    GtkWidget *ok_button = gtk_button_new_with_label("OK");
    GtkWidget *cancel_button = gtk_button_new_with_label("Cancel");
    
    gtk_box_pack_start(GTK_BOX(button_box), cancel_button, FALSE, FALSE, 0);
    gtk_box_pack_start(GTK_BOX(button_box), ok_button, FALSE, FALSE, 0);
    gtk_box_pack_start(GTK_BOX(vbox), button_box, FALSE, TRUE, 5);
    
    gtk_container_add(GTK_CONTAINER(gui->window), vbox);
    
    return gui;
}

void watermark_gui_show(WatermarkGUI *gui) {
    if (gui && gui->window) {
        gtk_widget_show_all(gui->window);
    }
}

void watermark_gui_destroy(WatermarkGUI *gui) {
    if (!gui) return;
    
    if (gui->window) {
        gtk_widget_destroy(gui->window);
    }
    
    watermark_free(gui->current_watermark);
    free(gui);
}
