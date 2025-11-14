/* subtitle_style_extended.h
 *
 * Extended subtitle styling options for HandBrake
 * Adds font size, color, and position controls
 */

#ifndef SUBTITLE_STYLE_EXTENDED_H
#define SUBTITLE_STYLE_EXTENDED_H

#include <stdint.h>

typedef struct {
    // Font properties
    char *font_name;
    int font_size;          // 12-255 pixels
    int bold;
    int italic;
    int underline;
    
    // Colors (RGBA format)
    uint32_t primary_color;   // Text color
    uint32_t secondary_color; // Karaoke/highlight color
    uint32_t outline_color;   // Border/outline
    uint32_t shadow_color;    // Shadow/background
    
    // Alpha values (0-255)
    uint8_t primary_alpha;
    uint8_t secondary_alpha;
    uint8_t outline_alpha;
    uint8_t shadow_alpha;
    
    // Position controls
    int position_x;         // X coordinate (0-100% of width)
    int position_y;         // Y coordinate (0-100% of height)
    int alignment;          // 1-9 (numpad layout: 1=bottom-left, 5=center, 9=top-right)
    int margin_left;
    int margin_right;
    int margin_vertical;
    
    // Advanced styling
    int outline_width;      // Border thickness
    int shadow_depth;       // Shadow distance
    int spacing;            // Letter spacing
    float scale_x;          // Horizontal scale (%)
    float scale_y;          // Vertical scale (%)
    float rotation;         // Text rotation (degrees)
} subtitle_style_extended_t;

// Function prototypes
subtitle_style_extended_t* subtitle_style_create_default();
void subtitle_style_apply(subtitle_style_extended_t *style, const char *ssa_header);
char* subtitle_style_to_ssa(subtitle_style_extended_t *style);
void subtitle_style_free(subtitle_style_extended_t *style);

#endif // SUBTITLE_STYLE_EXTENDED_H
