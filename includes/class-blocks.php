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
	 * Fallback animation type for unknown values
	 */
	const DEFAULT_TYPE = 'fade-in';

	/**
	 * Initialize hooks
	 */
	public static function init() {
		add_filter( 'render_block', array( __CLASS__, 'add_animation_data_attributes' ), 10, 2 );
	}

	/**
	 * Add the animation class, custom properties and data attribute to animated blocks
	 *
	 * Also enqueues the frontend assets, which is what makes animations work in every
	 * context: dynamic blocks, block templates, template parts and synced patterns.
	 *
	 * @param string $block_content Block HTML content.
	 * @param array  $block         Block data.
	 * @return string Modified block content.
	 */
	public static function add_animation_data_attributes( $block_content, $block ) {
		if ( empty( $block['attrs']['isAnimated'] ) ) {
			return $block_content;
		}

		if ( '' === trim( (string) $block_content ) ) {
			return $block_content;
		}

		$processor = new WP_HTML_Tag_Processor( $block_content );
		if ( ! $processor->next_tag() ) {
			return $block_content;
		}

		$animation_type = self::sanitize_animation_type( $block['attrs']['animationType'] ?? self::DEFAULT_TYPE );
		$duration       = self::clamp( $block['attrs']['animationDuration'] ?? 0.6, 0.2, 2 );
		$delay          = self::clamp( $block['attrs']['animationDelay'] ?? 0, 0, 1 );

		$processor->add_class( 'animate-' . $animation_type );
		$processor->set_attribute( 'data-animation', $animation_type );

		$inline_style = sprintf( '--animation-duration:%.3Fs;--animation-delay:%.3Fs;', $duration, $delay );
		$existing     = self::strip_animation_properties( $processor->get_attribute( 'style' ) );

		if ( '' !== $existing ) {
			$inline_style = $existing . ';' . $inline_style;
		}

		$processor->set_attribute( 'style', $inline_style );

		SIMPBLAN_Enqueue::enqueue_frontend_assets();

		return $processor->get_updated_html();
	}

	/**
	 * Drop our own custom properties from an existing style attribute
	 *
	 * Static blocks already carry them, written at save time by the editor filter.
	 * Removing them here keeps this filter authoritative instead of appending a
	 * second, duplicated pair.
	 *
	 * @param string|null $style Existing style attribute.
	 * @return string Style attribute without the animation custom properties.
	 */
	private static function strip_animation_properties( $style ) {
		if ( ! is_string( $style ) || '' === trim( $style ) ) {
			return '';
		}

		$kept = array();

		foreach ( explode( ';', $style ) as $declaration ) {
			$declaration = trim( $declaration );

			if ( '' === $declaration ) {
				continue;
			}

			if ( preg_match( '/^--animation-(duration|delay)\s*:/i', $declaration ) ) {
				continue;
			}

			$kept[] = $declaration;
		}

		return implode( ';', $kept );
	}

	/**
	 * Restrict the animation type to the supported list
	 *
	 * @param mixed $type Raw animation type from block attributes.
	 * @return string Supported animation type.
	 */
	private static function sanitize_animation_type( $type ) {
		// Keys never change with the locale, so they are safe to cache for the request.
		static $keys = null;

		if ( null === $keys ) {
			$keys = array_keys( self::get_animation_types() );
		}

		return ( is_string( $type ) && in_array( $type, $keys, true ) ) ? $type : self::DEFAULT_TYPE;
	}

	/**
	 * Cast to float and constrain to a range
	 *
	 * @param mixed $value Raw value.
	 * @param float $min   Lower bound.
	 * @param float $max   Upper bound.
	 * @return float Constrained value.
	 */
	private static function clamp( $value, $min, $max ) {
		return max( $min, min( $max, (float) $value ) );
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
			'zoom-in'       => __( 'Zoom avant', 'simple-block-animations' ),
			'slide-up'      => __( 'Glissement vers le haut', 'simple-block-animations' ),
		);
	}
}
