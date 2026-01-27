<?php
/**
 * Block registration and management
 *
 * @package SIMPBLAN
 */

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

/**
 * Handles block-related functionality
 */
class SIMPBLAN_Blocks {

	/**
	 * Initialize hooks
	 */
	public static function init() {
		add_filter( 'render_block', array( __CLASS__, 'add_animation_data_attributes' ), 10, 2 );
	}

	/**
	 * Add data attributes to animated blocks for better JS targeting
	 *
	 * @param string $block_content Block HTML content.
	 * @param array  $block         Block data.
	 * @return string Modified block content.
	 */
	public static function add_animation_data_attributes( $block_content, $block ) {
		// Check if block has animation attributes
		if ( empty( $block['attrs']['isAnimated'] ) || ! $block['attrs']['isAnimated'] ) {
			return $block_content;
		}

		// Get animation attributes
		$animation_type     = $block['attrs']['animationType'] ?? 'fade-in';
		$animation_duration = $block['attrs']['animationDuration'] ?? 0.6;
		$animation_delay    = $block['attrs']['animationDelay'] ?? 0;

		// Build animation class and data attributes
		$animation_class = 'animate-' . esc_attr( $animation_type );
		$data_attr       = sprintf(
			' data-animation="%s"',
			esc_attr( $animation_type )
		);
		
		// Build inline styles for animation
		$inline_style = sprintf(
			'--animation-duration:%ss;--animation-delay:%ss;',
			esc_attr( $animation_duration ),
			esc_attr( $animation_delay )
		);

		// Check if block content has an opening tag
		if ( empty( trim( $block_content ) ) ) {
			return $block_content;
		}

		// Insert class, style, and data attribute into opening tag
		$block_content = preg_replace_callback(
			'/^(<[a-z][a-z0-9]*)((?:\s+[^>]*)?)(>)/i',
			function ( $matches ) use ( $animation_class, $data_attr, $inline_style ) {
				$tag        = $matches[1];
				$attributes = $matches[2];
				$close      = $matches[3];

				// Add animation class
				if ( preg_match( '/class=["\']([^"\']*)["\']/', $attributes ) ) {
					// Class attribute exists, append to it
					$attributes = preg_replace(
						'/class=["\']([^"\']*)["\']/',
						'class="$1 ' . $animation_class . '"',
						$attributes
					);
				} else {
					// No class attribute, add it
					$attributes .= ' class="' . $animation_class . '"';
				}

				// Add or append to style attribute
				if ( preg_match( '/style=["\']([^"\']*)["\']/', $attributes ) ) {
					// Style attribute exists, append to it
					$attributes = preg_replace(
						'/style=["\']([^"\']*)["\']/',
						'style="$1' . $inline_style . '"',
						$attributes
					);
				} else {
					// No style attribute, add it
					$attributes .= ' style="' . $inline_style . '"';
				}

				// Add data attribute
				$attributes .= $data_attr;

				return $tag . $attributes . $close;
			},
			$block_content,
			1
		);

		return $block_content;
	}

	/**
	 * Get list of supported animation types
	 *
	 * @return array Animation types with labels.
	 */
	public static function get_animation_types() {
		return array(
			'fade-in'       => __( 'Fondu', 'simple-block-animations' ),
			'fade-in-up'    => __( 'Fondu - Bas vers haut', 'simple-block-animations' ),
			'fade-in-down'  => __( 'Fondu - Haut vers bas', 'simple-block-animations' ),
			'fade-in-left'  => __( 'Fondu - Gauche vers droite', 'simple-block-animations' ),
			'fade-in-right' => __( 'Fondu - Droite vers gauche', 'simple-block-animations' ),
		);
	}
}