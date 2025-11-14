/* subtitle_editor_gui.c
 *
 * GTK GUI pre rozšírené editovanie titulkov
 * Obsahuje kontroly pre veľkosť, farbu a pozíciu
 */

#include <gtk/gtk.h>
#include "subtitle_style_extended.h"

typedef struct {
    GtkWidget *window;
    GtkWidget *notebook;
    
    // Font tab widgets
    GtkWidget *font_button;
    GtkWidget *font_size_spin;
    GtkWidget *bold_check;
    GtkWidget *italic_check;
    GtkWidget *underline_check;
    
    // Color tab widgets
    GtkWidget *primary_color_button;
    GtkWidget *secondary_color_button;
    GtkWidget *outline_color_button;
    GtkWidget *shadow_color_button;
    GtkWidget *primary_alpha_scale;
    GtkWidget *secondary_alpha_scale;
    GtkWidget *outline_alpha_scale;
    GtkWidget *shadow_alpha_scale;
    
    // Position tab widgets
    GtkWidget *position_x_spin;
    GtkWidget *position_y_spin;
    GtkWidget *alignment_combo;
    GtkWidget *margin_left_spin;
    GtkWidget *margin_right_spin;
    GtkWidget *margin_vertical_spin;
    
    // Advanced tab widgets
    GtkWidget *outline_width_spin;
    GtkWidget *shadow_depth_spin;
    GtkWidget *spacing_spin;
    GtkWidget *scale_x_spin;
    GtkWidget *scale_y_spin;
    GtkWidget *rotation_spin;
    
    // Preview
    GtkWidget *preview_label;
    
    subtitle_style_extended_t *current_style;
} SubtitleEditorGUI;

static void update_preview(SubtitleEditorGUI *editor) {
    if (!editor || !editor->preview_label) return;
    
    char preview_text[512];
    snprintf(preview_text, sizeof(preview_text),
        "<span font_desc='%s %d' foreground='#%06X'>Subtitle Style Sample</span>",
        editor->current_style->font_name,
        editor->current_style->font_size,
        editor->current_style->primary_color
    );
    
    gtk_label_set_markup(GTK_LABEL(editor->preview_label), preview_text);
}

static void on_font_size_changed(GtkSpinButton *spin, gpointer user_data) {
    SubtitleEditorGUI *editor = (SubtitleEditorGUI*)user_data;
    editor->current_style->font_size = gtk_spin_button_get_value_as_int(spin);
    update_preview(editor);
}

static void on_position_x_changed(GtkSpinButton *spin, gpointer user_data) {
    SubtitleEditorGUI *editor = (SubtitleEditorGUI*)user_data;
    editor->current_style->position_x = gtk_spin_button_get_value_as_int(spin);
}

static void on_position_y_changed(GtkSpinButton *spin, gpointer user_data) {
    SubtitleEditorGUI *editor = (SubtitleEditorGUI*)user_data;
    editor->current_style->position_y = gtk_spin_button_get_value_as_int(spin);
}

static void on_primary_color_set(GtkColorButton *button, gpointer user_data) {
    SubtitleEditorGUI *editor = (SubtitleEditorGUI*)user_data;
    GdkRGBA color;
    gtk_color_chooser_get_rgba(GTK_COLOR_CHOOSER(button), &color);
    
    editor->current_style->primary_color = 
        ((int)(color.red * 255) << 16) |
        ((int)(color.green * 255) << 8) |
        (int)(color.blue * 255);
    
    update_preview(editor);
}

static void on_primary_alpha_changed(GtkRange *range, gpointer user_data) {
    SubtitleEditorGUI *editor = (SubtitleEditorGUI*)user_data;
    editor->current_style->primary_alpha = (uint8_t)gtk_range_get_value(range);
}

static GtkWidget* create_font_tab(SubtitleEditorGUI *editor) {
    GtkWidget *grid = gtk_grid_new();
    gtk_grid_set_row_spacing(GTK_GRID(grid), 10);
    gtk_grid_set_column_spacing(GTK_GRID(grid), 10);
    gtk_container_set_border_width(GTK_CONTAINER(grid), 10);
    
    // Font family
    GtkWidget *font_label = gtk_label_new("Font:");
    gtk_widget_set_halign(font_label, GTK_ALIGN_START);
    editor->font_button = gtk_font_button_new();
    gtk_grid_attach(GTK_GRID(grid), font_label, 0, 0, 1, 1);
    gtk_grid_attach(GTK_GRID(grid), editor->font_button, 1, 0, 2, 1);
    
    // Font size
    GtkWidget *size_label = gtk_label_new("Size (12-255 px):");
    gtk_widget_set_halign(size_label, GTK_ALIGN_START);
    editor->font_size_spin = gtk_spin_button_new_with_range(12, 255, 1);
    gtk_spin_button_set_value(GTK_SPIN_BUTTON(editor->font_size_spin), 24);
    g_signal_connect(editor->font_size_spin, "value-changed", 
                     G_CALLBACK(on_font_size_changed), editor);
    gtk_grid_attach(GTK_GRID(grid), size_label, 0, 1, 1, 1);
    gtk_grid_attach(GTK_GRID(grid), editor->font_size_spin, 1, 1, 2, 1);
    
    // Style checkboxes
    editor->bold_check = gtk_check_button_new_with_label("Bold");
    editor->italic_check = gtk_check_button_new_with_label("Italic");
    editor->underline_check = gtk_check_button_new_with_label("Underline");
    
    gtk_grid_attach(GTK_GRID(grid), editor->bold_check, 0, 2, 1, 1);
    gtk_grid_attach(GTK_GRID(grid), editor->italic_check, 1, 2, 1, 1);
    gtk_grid_attach(GTK_GRID(grid), editor->underline_check, 2, 2, 1, 1);
    
    return grid;
}

static GtkWidget* create_color_tab(SubtitleEditorGUI *editor) {
    GtkWidget *grid = gtk_grid_new();
    gtk_grid_set_row_spacing(GTK_GRID(grid), 10);
    gtk_grid_set_column_spacing(GTK_GRID(grid), 10);
    gtk_container_set_border_width(GTK_CONTAINER(grid), 10);
    
    // Primary color
    GtkWidget *primary_label = gtk_label_new("Text Color:");
    gtk_widget_set_halign(primary_label, GTK_ALIGN_START);
    editor->primary_color_button = gtk_color_button_new();
    GdkRGBA primary_color = {1.0, 1.0, 1.0, 1.0};  // White
    gtk_color_chooser_set_rgba(GTK_COLOR_CHOOSER(editor->primary_color_button), &primary_color);
    g_signal_connect(editor->primary_color_button, "color-set",
                     G_CALLBACK(on_primary_color_set), editor);
    gtk_grid_attach(GTK_GRID(grid), primary_label, 0, 0, 1, 1);
    gtk_grid_attach(GTK_GRID(grid), editor->primary_color_button, 1, 0, 1, 1);
    
    // Primary alpha
    GtkWidget *alpha_label = gtk_label_new("Transparency (0-100):");
    gtk_widget_set_halign(alpha_label, GTK_ALIGN_START);
    editor->primary_alpha_scale = gtk_scale_new_with_range(GTK_ORIENTATION_HORIZONTAL, 0, 255, 1);
    gtk_range_set_value(GTK_RANGE(editor->primary_alpha_scale), 255);
    gtk_scale_set_draw_value(GTK_SCALE(editor->primary_alpha_scale), TRUE);
    g_signal_connect(editor->primary_alpha_scale, "value-changed",
                     G_CALLBACK(on_primary_alpha_changed), editor);
    gtk_grid_attach(GTK_GRID(grid), alpha_label, 0, 1, 1, 1);
    gtk_grid_attach(GTK_GRID(grid), editor->primary_alpha_scale, 1, 1, 2, 1);
    
    // Outline color
    GtkWidget *outline_label = gtk_label_new("Outline Color:");
    gtk_widget_set_halign(outline_label, GTK_ALIGN_START);
    editor->outline_color_button = gtk_color_button_new();
    GdkRGBA outline_color = {0.0, 0.0, 0.0, 1.0};  // Black
    gtk_color_chooser_set_rgba(GTK_COLOR_CHOOSER(editor->outline_color_button), &outline_color);
    gtk_grid_attach(GTK_GRID(grid), outline_label, 0, 2, 1, 1);
    gtk_grid_attach(GTK_GRID(grid), editor->outline_color_button, 1, 2, 1, 1);
    
    // Shadow color
    GtkWidget *shadow_label = gtk_label_new("Shadow Color:");
    gtk_widget_set_halign(shadow_label, GTK_ALIGN_START);
    editor->shadow_color_button = gtk_color_button_new();
    GdkRGBA shadow_color = {0.0, 0.0, 0.0, 0.5};  // Semi-transparent black
    gtk_color_chooser_set_rgba(GTK_COLOR_CHOOSER(editor->shadow_color_button), &shadow_color);
    gtk_grid_attach(GTK_GRID(grid), shadow_label, 0, 3, 1, 1);
    gtk_grid_attach(GTK_GRID(grid), editor->shadow_color_button, 1, 3, 1, 1);
    
    return grid;
}

static GtkWidget* create_position_tab(SubtitleEditorGUI *editor) {
    GtkWidget *grid = gtk_grid_new();
    gtk_grid_set_row_spacing(GTK_GRID(grid), 10);
    gtk_grid_set_column_spacing(GTK_GRID(grid), 10);
    gtk_container_set_border_width(GTK_CONTAINER(grid), 10);
    
    // X position
    GtkWidget *x_label = gtk_label_new("X Position (0-100%):");
    gtk_widget_set_halign(x_label, GTK_ALIGN_START);
    editor->position_x_spin = gtk_spin_button_new_with_range(0, 100, 1);
    gtk_spin_button_set_value(GTK_SPIN_BUTTON(editor->position_x_spin), 50);
    g_signal_connect(editor->position_x_spin, "value-changed",
                     G_CALLBACK(on_position_x_changed), editor);
    gtk_grid_attach(GTK_GRID(grid), x_label, 0, 0, 1, 1);
    gtk_grid_attach(GTK_GRID(grid), editor->position_x_spin, 1, 0, 2, 1);
    
    // Y position
    GtkWidget *y_label = gtk_label_new("Y Position (0-100%):");
    gtk_widget_set_halign(y_label, GTK_ALIGN_START);
    editor->position_y_spin = gtk_spin_button_new_with_range(0, 100, 1);
    gtk_spin_button_set_value(GTK_SPIN_BUTTON(editor->position_y_spin), 90);
    g_signal_connect(editor->position_y_spin, "value-changed",
                     G_CALLBACK(on_position_y_changed), editor);
    gtk_grid_attach(GTK_GRID(grid), y_label, 0, 1, 1, 1);
    gtk_grid_attach(GTK_GRID(grid), editor->position_y_spin, 1, 1, 2, 1);
    
    // Alignment
    GtkWidget *align_label = gtk_label_new("Alignment:");
    gtk_widget_set_halign(align_label, GTK_ALIGN_START);
    editor->alignment_combo = gtk_combo_box_text_new();
    gtk_combo_box_text_append_text(GTK_COMBO_BOX_TEXT(editor->alignment_combo), "Bottom Left (1)");
    gtk_combo_box_text_append_text(GTK_COMBO_BOX_TEXT(editor->alignment_combo), "Bottom Center (2)");
    gtk_combo_box_text_append_text(GTK_COMBO_BOX_TEXT(editor->alignment_combo), "Bottom Right (3)");
    gtk_combo_box_text_append_text(GTK_COMBO_BOX_TEXT(editor->alignment_combo), "Middle Left (4)");
    gtk_combo_box_text_append_text(GTK_COMBO_BOX_TEXT(editor->alignment_combo), "Middle Center (5)");
    gtk_combo_box_text_append_text(GTK_COMBO_BOX_TEXT(editor->alignment_combo), "Middle Right (6)");
    gtk_combo_box_text_append_text(GTK_COMBO_BOX_TEXT(editor->alignment_combo), "Top Left (7)");
    gtk_combo_box_text_append_text(GTK_COMBO_BOX_TEXT(editor->alignment_combo), "Top Center (8)");
    gtk_combo_box_text_append_text(GTK_COMBO_BOX_TEXT(editor->alignment_combo), "Top Right (9)");
    gtk_combo_box_set_active(GTK_COMBO_BOX(editor->alignment_combo), 1);  // Bottom Center
    gtk_grid_attach(GTK_GRID(grid), align_label, 0, 2, 1, 1);
    gtk_grid_attach(GTK_GRID(grid), editor->alignment_combo, 1, 2, 2, 1);
    
    // Margins
    GtkWidget *margin_label = gtk_label_new("Margins:");
    gtk_widget_set_halign(margin_label, GTK_ALIGN_START);
    gtk_grid_attach(GTK_GRID(grid), margin_label, 0, 3, 3, 1);
    
    GtkWidget *left_label = gtk_label_new("  Left:");
    gtk_widget_set_halign(left_label, GTK_ALIGN_START);
    editor->margin_left_spin = gtk_spin_button_new_with_range(0, 100, 1);
    gtk_spin_button_set_value(GTK_SPIN_BUTTON(editor->margin_left_spin), 10);
    gtk_grid_attach(GTK_GRID(grid), left_label, 0, 4, 1, 1);
    gtk_grid_attach(GTK_GRID(grid), editor->margin_left_spin, 1, 4, 2, 1);
    
    GtkWidget *right_label = gtk_label_new("  Right:");
    gtk_widget_set_halign(right_label, GTK_ALIGN_START);
    editor->margin_right_spin = gtk_spin_button_new_with_range(0, 100, 1);
    gtk_spin_button_set_value(GTK_SPIN_BUTTON(editor->margin_right_spin), 10);
    gtk_grid_attach(GTK_GRID(grid), right_label, 0, 5, 1, 1);
    gtk_grid_attach(GTK_GRID(grid), editor->margin_right_spin, 1, 5, 2, 1);
    
    GtkWidget *vertical_label = gtk_label_new("  Vertical:");
    gtk_widget_set_halign(vertical_label, GTK_ALIGN_START);
    editor->margin_vertical_spin = gtk_spin_button_new_with_range(0, 100, 1);
    gtk_spin_button_set_value(GTK_SPIN_BUTTON(editor->margin_vertical_spin), 10);
    gtk_grid_attach(GTK_GRID(grid), vertical_label, 0, 6, 1, 1);
    gtk_grid_attach(GTK_GRID(grid), editor->margin_vertical_spin, 1, 6, 2, 1);
    
    return grid;
}

SubtitleEditorGUI* subtitle_editor_create() {
    SubtitleEditorGUI *editor = malloc(sizeof(SubtitleEditorGUI));
    if (!editor) return NULL;
    
    editor->current_style = subtitle_style_create_default();
    
    // Create main window
    editor->window = gtk_window_new(GTK_WINDOW_TOPLEVEL);
    gtk_window_set_title(GTK_WINDOW(editor->window), "Subtitle Style Editor");
    gtk_window_set_default_size(GTK_WINDOW(editor->window), 500, 600);
    
    // Create notebook for tabs
    editor->notebook = gtk_notebook_new();
    
    // Add tabs
    gtk_notebook_append_page(GTK_NOTEBOOK(editor->notebook),
                            create_font_tab(editor),
                            gtk_label_new("Font"));
    
    gtk_notebook_append_page(GTK_NOTEBOOK(editor->notebook),
                            create_color_tab(editor),
                            gtk_label_new("Colors"));
    
    gtk_notebook_append_page(GTK_NOTEBOOK(editor->notebook),
                            create_position_tab(editor),
                            gtk_label_new("Position"));
    
    // Preview area
    GtkWidget *preview_frame = gtk_frame_new("Preview");
    editor->preview_label = gtk_label_new("Subtitle Style Sample");
    gtk_container_add(GTK_CONTAINER(preview_frame), editor->preview_label);
    
    // Main layout
    GtkWidget *vbox = gtk_box_new(GTK_ORIENTATION_VERTICAL, 5);
    gtk_box_pack_start(GTK_BOX(vbox), editor->notebook, TRUE, TRUE, 0);
    gtk_box_pack_start(GTK_BOX(vbox), preview_frame, FALSE, TRUE, 0);
    
    // Buttons
    GtkWidget *button_box = gtk_button_box_new(GTK_ORIENTATION_HORIZONTAL);
    gtk_button_box_set_layout(GTK_BUTTON_BOX(button_box), GTK_BUTTONBOX_END);
    
    GtkWidget *ok_button = gtk_button_new_with_label("OK");
    GtkWidget *cancel_button = gtk_button_new_with_label("Cancel");
    
    gtk_box_pack_start(GTK_BOX(button_box), cancel_button, FALSE, FALSE, 0);
    gtk_box_pack_start(GTK_BOX(button_box), ok_button, FALSE, FALSE, 0);
    gtk_box_pack_start(GTK_BOX(vbox), button_box, FALSE, TRUE, 5);
    
    gtk_container_add(GTK_CONTAINER(editor->window), vbox);
    
    update_preview(editor);
    
    return editor;
}

void subtitle_editor_show(SubtitleEditorGUI *editor) {
    if (editor && editor->window) {
        gtk_widget_show_all(editor->window);
    }
}

void subtitle_editor_destroy(SubtitleEditorGUI *editor) {
    if (!editor) return;
    
    if (editor->window) {
        gtk_widget_destroy(editor->window);
    }
    
    subtitle_style_free(editor->current_style);
    free(editor);
}
