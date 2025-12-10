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

		// Only process core and meta-box blocks
		if ( ! isset( $block['blockName'] ) ||
			 ( ! str_starts_with( $block['blockName'], 'core/' ) &&
			   ! str_starts_with( $block['blockName'], 'meta-box/' ) ) ) {
			return $block_content;
		}

		// Add data attributes for JS
		$animation_type = $block['attrs']['animationType'] ?? 'fade-in';
		$data_attr      = sprintf(
			' data-animation="%s"',
			esc_attr( $animation_type )
		);

		// Insert data attribute into opening tag
		$block_content = preg_replace(
			'/^(<[a-z][a-z0-9]*)/i',
			'$1' . $data_attr,
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