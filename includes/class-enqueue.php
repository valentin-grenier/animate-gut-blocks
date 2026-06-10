<?php
/**
 * Asset management class
 *
 * @package SIMPBLAN
 */

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

/**
 * Handles enqueueing of editor and frontend assets
 */
class SIMPBLAN_Enqueue {

	/**
	 * Initialize hooks
	 */
	public static function init() {
		add_action( 'enqueue_block_editor_assets', array( __CLASS__, 'enqueue_editor_assets' ) );
		add_action( 'wp_enqueue_scripts', array( __CLASS__, 'enqueue_frontend_assets' ) );
	}

	/**
	 * Enqueue editor assets (Block Editor only)
	 */
	public static function enqueue_editor_assets() {
		// Editor JS
		wp_enqueue_script(
			'simple-block-animations-editor',
			SIMPBLAN_URL . 'build/editor.js',
			array( 'wp-blocks', 'wp-dom', 'wp-i18n', 'wp-hooks', 'wp-compose', 'wp-element', 'wp-block-editor', 'wp-components' ),
			SIMPBLAN_VERSION,
			true
		);

		// Editor CSS
		wp_enqueue_style(
			'simple-block-animations-editor',
			SIMPBLAN_URL . 'build/editor.css',
			array( 'wp-edit-blocks' ),
			SIMPBLAN_VERSION
		);

		// Set script translations
		wp_set_script_translations(
			'simple-block-animations-editor',
			'simple-block-animations',
			SIMPBLAN_PATH . 'languages'
		);
	}

	/**
	 * Enqueue frontend assets (only if animated blocks are present)
	 */
	public static function enqueue_frontend_assets() {
		// Check if we're in editor or if page has animated blocks
		if ( is_admin() || ! self::page_has_animated_blocks() ) {
			return;
		}

		// Frontend JS (Intersection Observer)
		wp_enqueue_script(
			'simple-block-animations-frontend',
			SIMPBLAN_URL . 'build/frontend.js',
			array(),
			SIMPBLAN_VERSION,
			true
		);

		// Frontend CSS (animations)
		wp_enqueue_style(
			'simple-block-animations-frontend',
			SIMPBLAN_URL . 'build/frontend.css',
			array(),
			SIMPBLAN_VERSION
		);
	}

	/**
	 * Check if current page/post has animated blocks
	 *
	 * @return bool
	 */
	private static function page_has_animated_blocks() {
		// For singular content
		if ( is_singular() ) {
			global $post;
			if ( $post && has_blocks( $post->post_content ) ) {
				return self::content_has_animation_classes( $post->post_content );
			}
		}

		// For archives, check query
		if ( is_archive() || is_home() ) {
			global $wp_query;
			if ( ! empty( $wp_query->posts ) ) {
				foreach ( $wp_query->posts as $post ) {
					if ( has_blocks( $post->post_content ) && self::content_has_animation_classes( $post->post_content ) ) {
						return true;
					}
				}
			}
		}

		return false;
	}

	/**
	 * Check if content contains animation classes
	 *
	 * @param string $content Post content.
	 * @return bool
	 */
	private static function content_has_animation_classes( $content ) {
		// Check for animate- classes in content
		return strpos( $content, 'animate-fade-in' ) !== false ||
			   strpos( $content, 'animate-fade-in-up' ) !== false ||
			   strpos( $content, 'animate-fade-in-down' ) !== false ||
			   strpos( $content, 'animate-fade-in-left' ) !== false ||
			   strpos( $content, 'animate-fade-in-right' ) !== false;
	}
}