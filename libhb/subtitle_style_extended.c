/* subtitle_style_extended.c
 *
 * Implementation of extended subtitle styling
 */

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "subtitle_style_extended.h"

subtitle_style_extended_t* subtitle_style_create_default() {
    subtitle_style_extended_t *style = malloc(sizeof(subtitle_style_extended_t));
    if (!style) return NULL;
    
    // Default values
    style->font_name = strdup("Arial");
    style->font_size = 24;
    style->bold = 0;
    style->italic = 0;
    style->underline = 0;
    
    // Default colors (white text, black outline)
    style->primary_color = 0xFFFFFF;      // White
    style->secondary_color = 0x00FF00;    // Green (for karaoke)
    style->outline_color = 0x000000;      // Black
    style->shadow_color = 0x000000;       // Black
    
    // Full opacity
    style->primary_alpha = 255;
    style->secondary_alpha = 255;
    style->outline_alpha = 255;
    style->shadow_alpha = 128;
    
    // Default position (bottom center)
    style->position_x = 50;               // Center horizontally
    style->position_y = 90;               // 90% down (near bottom)
    style->alignment = 2;                 // Bottom center
    style->margin_left = 10;
    style->margin_right = 10;
    style->margin_vertical = 10;
    
    // Advanced styling defaults
    style->outline_width = 2;
    style->shadow_depth = 2;
    style->spacing = 0;
    style->scale_x = 100.0f;
    style->scale_y = 100.0f;
    style->rotation = 0.0f;
    
    return style;
}

char* subtitle_style_to_ssa(subtitle_style_extended_t *style) {
    if (!style) return NULL;
    
    // Convert RGB to BGR format (SSA uses BGR)
    uint32_t primary_bgr = ((style->primary_color & 0xFF) << 16) | 
                           (style->primary_color & 0xFF00) | 
                           ((style->primary_color >> 16) & 0xFF);
    uint32_t secondary_bgr = ((style->secondary_color & 0xFF) << 16) | 
                             (style->secondary_color & 0xFF00) | 
                             ((style->secondary_color >> 16) & 0xFF);
    uint32_t outline_bgr = ((style->outline_color & 0xFF) << 16) | 
                           (style->outline_color & 0xFF00) | 
                           ((style->outline_color >> 16) & 0xFF);
    uint32_t shadow_bgr = ((style->shadow_color & 0xFF) << 16) | 
                          (style->shadow_color & 0xFF00) | 
                          ((style->shadow_color >> 16) & 0xFF);
    
    // SSA alpha is inverted (0 = opaque, 255 = transparent)
    uint8_t primary_alpha_ssa = 255 - style->primary_alpha;
    uint8_t secondary_alpha_ssa = 255 - style->secondary_alpha;
    uint8_t outline_alpha_ssa = 255 - style->outline_alpha;
    uint8_t shadow_alpha_ssa = 255 - style->shadow_alpha;
    
    // Combine color and alpha into SSA format (&HAABBGGRR)
    uint32_t primary_abgr = (primary_alpha_ssa << 24) | primary_bgr;
    uint32_t secondary_abgr = (secondary_alpha_ssa << 24) | secondary_bgr;
    uint32_t outline_abgr = (outline_alpha_ssa << 24) | outline_bgr;
    uint32_t shadow_abgr = (shadow_alpha_ssa << 24) | shadow_bgr;
    
    char *ssa_string = malloc(2048);
    if (!ssa_string) return NULL;
    
    // Generate complete SSA style line
    snprintf(ssa_string, 2048,
        "Style: Extended,%s,%d,&H%08X,&H%08X,&H%08X,&H%08X,%d,%d,%d,0,%.0f,%.0f,%d,%.2f,1,%d,%d,%d,%d,%d,%d,1",
        style->font_name,
        style->font_size,
        primary_abgr,
        secondary_abgr,
        outline_abgr,
        shadow_abgr,
        style->bold ? -1 : 0,
        style->italic ? -1 : 0,
        style->underline ? -1 : 0,
        style->scale_x,
        style->scale_y,
        style->spacing,
        style->rotation,
        style->outline_width,
        style->shadow_depth,
        style->alignment,
        style->margin_left,
        style->margin_right,
        style->margin_vertical
    );
    
    return ssa_string;
}

void subtitle_style_apply(subtitle_style_extended_t *style, const char *ssa_header) {
    // Parse existing SSA header and apply style modifications
    // This would integrate with HandBrake's existing ssautil.c functions
    if (!style || !ssa_header) return;
    
    // Implementation would parse and modify SSA header
    // For now, this is a placeholder for integration
}

void subtitle_style_free(subtitle_style_extended_t *style) {
    if (!style) return;
    free(style->font_name);
    free(style);
}
