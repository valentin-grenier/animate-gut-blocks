<?php 

/**
 * Plugin Name: Simple block animations
 * Plugin URI: https://github.com/valentin-grenier/simple-animations-for-gutenberg
 * Description: Easily add animations to your Gutenberg blocks without coding.
 * Version: 1.2.0
 * Requires at least: 
 * Requires PHP: 
 * Tested up to: 6.9
 * Author: Valentin Grenier
 * Author URI: https://www.linkedin.com/in/valentin-grenier/
 * License: GPL v2 or later
 * License URI: https://www.gnu.org/licenses/gpl-2.0.html
 * Text Domain: simple-block-animations
 * Domain Path: /languages
 */

// Exit if accessed directly.
if ( ! defined( 'ABSPATH' ) ) {
    exit;
}

define( 'SIMPBLAN_VERSION', '1.2.0' );
define( 'SIMPBLAN_PATH', plugin_dir_path( __FILE__ ) );
define( 'SIMPBLAN_URL', plugin_dir_url( __FILE__ ) );

require_once SIMPBLAN_PATH . 'includes/class-enqueue.php';
require_once SIMPBLAN_PATH . 'includes/class-blocks.php';
require_once SIMPBLAN_PATH . 'includes/class-settings.php';

/**
 * Initialize plugin
 */
function simpblan_init() {
	SIMPBLAN_Enqueue::init();
	SIMPBLAN_Blocks::init();
	SIMPBLAN_Settings::init();
}
add_action( 'plugins_loaded', 'simpblan_init' );

/**
 * Activation hook
 */
function simpblan_activate() {
	// Set default options
	if ( ! get_option( SIMPBLAN_Settings::OPTION_NAME ) ) {
		add_option(
			SIMPBLAN_Settings::OPTION_NAME,
			array(
				'default_duration' => 0.6,
				'default_delay'    => 0,
			)
		);
	}

	flush_rewrite_rules();
}
register_activation_hook( __FILE__, 'simpblan_activate' );

/**
 * Deactivation hook
 */
function simpblan_deactivate() {
	flush_rewrite_rules();
}
register_deactivation_hook( __FILE__, 'simpblan_deactivate' );