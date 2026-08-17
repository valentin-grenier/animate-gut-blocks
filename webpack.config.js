const defaultConfig = require( '@wordpress/scripts/config/webpack.config' );

const isProduction = process.env.NODE_ENV === 'production';

module.exports = {
	...defaultConfig,
	entry: {
		editor: './src/js/editor.js',
		frontend: './src/js/frontend.js',
	},
	plugins: defaultConfig.plugins.filter(
		( plugin ) => plugin.constructor.name !== 'RtlCssPlugin'
	),
	devtool: isProduction ? false : 'source-map',
};
