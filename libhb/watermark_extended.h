/* watermark_extended.h
 *
 * Extended watermark support for HandBrake
 * Adds image and text watermarks with precise positioning
 */

#ifndef WATERMARK_EXTENDED_H
#define WATERMARK_EXTENDED_H

#include <stdint.h>

typedef enum {
    WATERMARK_TYPE_NONE = 0,
    WATERMARK_TYPE_IMAGE,
    WATERMARK_TYPE_TEXT
} watermark_type_t;

typedef enum {
    WATERMARK_POSITION_CUSTOM = 0,
    WATERMARK_POSITION_TOP_LEFT,
    WATERMARK_POSITION_TOP_CENTER,
    WATERMARK_POSITION_TOP_RIGHT,
    WATERMARK_POSITION_MIDDLE_LEFT,
    WATERMARK_POSITION_MIDDLE_CENTER,
    WATERMARK_POSITION_MIDDLE_RIGHT,
    WATERMARK_POSITION_BOTTOM_LEFT,
    WATERMARK_POSITION_BOTTOM_CENTER,
    WATERMARK_POSITION_BOTTOM_RIGHT
} watermark_position_preset_t;

typedef struct {
    watermark_type_t type;
    
    // Image watermark
    char *image_path;           // Path to image file (PNG, JPG)
    int image_width;            // Scaled width (0 = original)
    int image_height;           // Scaled height (0 = original)
    
    // Text watermark
    char *text;                 // Watermark text
    char *font_name;            // Font family
    int font_size;              // Font size in pixels
    uint32_t text_color;        // RGB color
    int text_bold;              // Bold flag
    int text_italic;            // Italic flag
    uint32_t outline_color;     // Text outline color
    int outline_width;          // Outline thickness
    
    // Position
    watermark_position_preset_t position_preset;
    int position_x;             // X coordinate (pixels or %)
    int position_y;             // Y coordinate (pixels or %)
    int use_percentage;         // 0 = pixels, 1 = percentage
    
    // Appearance
    int opacity;                // 0-100%
    int rotation;               // Rotation angle (degrees)
    
    // Margins (when using presets)
    int margin_x;
    int margin_y;
    
} watermark_extended_t;

// Function prototypes
watermark_extended_t* watermark_create();
void watermark_free(watermark_extended_t *wm);
void watermark_set_image(watermark_extended_t *wm, const char *path);
void watermark_set_text(watermark_extended_t *wm, const char *text);
void watermark_set_position_xy(watermark_extended_t *wm, int x, int y, int use_percentage);
void watermark_set_position_preset(watermark_extended_t *wm, watermark_position_preset_t preset);
char* watermark_to_ffmpeg_filter(watermark_extended_t *wm, int video_width, int video_height);

#endif // WATERMARK_EXTENDED_H
