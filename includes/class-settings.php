<?php
/**
 * Plugin settings management
 *
 * @package SIMPBLAN
 */

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

/**
 * Handles plugin settings and options page
 */
class SIMPBLAN_Settings {

	/**
	 * Option name in database
	 */
	const OPTION_NAME = 'simpblan_settings';

	/**
	 * Initialize hooks
	 */
	public static function init() {
		add_action( 'admin_menu', array( __CLASS__, 'add_settings_page' ) );
		add_action( 'admin_init', array( __CLASS__, 'register_settings' ) );
	}

	/**
	 * Add settings page to WordPress admin
	 */
	public static function add_settings_page() {
		add_options_page(
			__( 'Block Animations Settings', 'simple-block-animations' ),
			__( 'Block Animations', 'simple-block-animations' ),
			'manage_options',
			'simple-block-animations',
			array( __CLASS__, 'render_settings_page' )
		);
	}

	/**
	 * Register plugin settings
	 */
	public static function register_settings() {
		register_setting(
			'simpblan_settings_group',
			self::OPTION_NAME,
			array(
				'type'              => 'array',
				'sanitize_callback' => array( __CLASS__, 'sanitize_settings' ),
				'default'           => self::get_default_settings(),
			)
		);

		add_settings_section(
			'simpblan_main',
			__( 'Configuration générale', 'simple-block-animations' ),
			array( __CLASS__, 'render_main_section' ),
			'simple-block-animations'
		);

		add_settings_field(
			'default_duration',
			__( 'Durée par défaut', 'simple-block-animations' ),
			array( __CLASS__, 'render_default_duration_field' ),
			'simple-block-animations',
			'simpblan_main'
		);
	}

	/**
	 * Get default settings
	 *
	 * @return array Default settings.
	 */
	private static function get_default_settings() {
		return array(
			'default_duration' => 0.6,
			'default_delay'    => 0,
		);
	}

	/**
	 * Sanitize settings
	 *
	 * @param array $input Raw input data.
	 * @return array Sanitized data.
	 */
	public static function sanitize_settings( $input ) {
		$sanitized = array();

		if ( isset( $input['default_duration'] ) ) {
			$sanitized['default_duration'] = (float) $input['default_duration'];
			$sanitized['default_duration'] = max( 0.2, min( 2, $sanitized['default_duration'] ) );
		}

		if ( isset( $input['default_delay'] ) ) {
			$sanitized['default_delay'] = (float) $input['default_delay'];
			$sanitized['default_delay'] = max( 0, min( 1, $sanitized['default_delay'] ) );
		}

		return $sanitized;
	}

	/**
	 * Render settings page
	 */
	public static function render_settings_page() {
		if ( ! current_user_can( 'manage_options' ) ) {
			return;
		}
		?>
		<div class="wrap">
			<h1><?php echo esc_html( get_admin_page_title() ); ?></h1>
			<form action="options.php" method="post">
				<?php
				settings_fields( 'simpblan_settings_group' );
				do_settings_sections( 'simple-block-animations' );
				submit_button();
				?>
			</form>
		</div>
		<?php
	}

	/**
	 * Render main section description
	 */
	public static function render_main_section() {
		echo '<p>' . esc_html__( 'Configurez les options par défaut pour les animations de blocs. Les animations sont maintenant supportées pour tous les types de blocs.', 'simple-block-animations' ) . '</p>';
	}

	/**
	 * Render default duration field
	 */
	public static function render_default_duration_field() {
		$options  = get_option( self::OPTION_NAME, self::get_default_settings() );
		$duration = $options['default_duration'] ?? 0.6;
		?>
		<input type="number" name="<?php echo esc_attr( self::OPTION_NAME ); ?>[default_duration]" value="<?php echo esc_attr( $duration ); ?>" min="0.2" max="2" step="0.1">
		<p class="description"><?php esc_html_e( 'Durée par défaut des animations en secondes (0.2 - 2)', 'simple-block-animations' ); ?></p>
		<?php
	}

	/**
	 * Get current settings
	 *
	 * @return array Current settings.
	 */
	public static function get_settings() {
		return get_option( self::OPTION_NAME, self::get_default_settings() );
	}
}