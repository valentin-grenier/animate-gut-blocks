import { __ } from '@wordpress/i18n';
import { addFilter } from '@wordpress/hooks';
import { createHigherOrderComponent } from '@wordpress/compose';
import { createElement, Fragment } from '@wordpress/element';
import { InspectorControls } from '@wordpress/block-editor';
import {
	PanelBody,
	ToggleControl,
	SelectControl,
	RangeControl,
} from '@wordpress/components';
import '../scss/editor.scss';

// Defaults come from the settings page, exposed by SIMPBLAN_Enqueue.
const pluginDefaults = window.simpblanDefaults || {};
const DEFAULT_DURATION = Number( pluginDefaults.default_duration ) || 0.6;
const DEFAULT_DELAY = Number( pluginDefaults.default_delay ) || 0;

// Prevent multiple executions
if ( ! window.simpleBlockAnimationsAttributesFiltersAdded ) {
	window.simpleBlockAnimationsAttributesFiltersAdded = true;

	/**
	 * Add animation attributes to all blocks
	 * Respects existing animation attributes if already defined in block.json
	 *
	 * @param {Object} settings Block settings.
	 * @return {Object} Block settings carrying the animation attributes.
	 */
	function addAnimationAttributes( settings ) {
		// Check if block already has animation attributes defined
		const hasIsAnimated =
			settings.attributes && settings.attributes.isAnimated;
		const hasAnimationType =
			settings.attributes && settings.attributes.animationType;
		const hasAnimationDuration =
			settings.attributes && settings.attributes.animationDuration;
		const hasAnimationDelay =
			settings.attributes && settings.attributes.animationDelay;

		// Only add attributes that don't already exist
		return {
			...settings,
			attributes: {
				...settings.attributes,
				// Only add if not already defined
				...( ! hasIsAnimated && {
					isAnimated: {
						type: 'boolean',
						default: false,
					},
				} ),
				...( ! hasAnimationType && {
					animationType: {
						type: 'string',
						default: 'fade-in',
					},
				} ),
				...( ! hasAnimationDuration && {
					animationDuration: {
						type: 'number',
						default: DEFAULT_DURATION,
					},
				} ),
				...( ! hasAnimationDelay && {
					animationDelay: {
						type: 'number',
						default: DEFAULT_DELAY,
					},
				} ),
			},
		};
	}

	/**
	 * Add animation controls to all blocks
	 */
	const withAnimationControls = createHigherOrderComponent( ( BlockEdit ) => {
		return ( props ) => {
			const { attributes, setAttributes } = props;
			const {
				isAnimated,
				animationType,
				animationDuration,
				animationDelay,
			} = attributes;

			// Skip if attributes are not available (edge case for some blocks)
			if ( ! attributes || typeof isAnimated === 'undefined' ) {
				return createElement( BlockEdit, props );
			}

			return createElement(
				Fragment,
				null,
				createElement( BlockEdit, props ),
				createElement(
					InspectorControls,
					{ group: 'settings' },
					createElement(
						PanelBody,
						{
							title: __(
								'Animations',
								'simple-block-animations'
							),
							initialOpen: true,
						},
						createElement( ToggleControl, {
							label: __(
								'Animer le bloc',
								'simple-block-animations'
							),
							checked: isAnimated,
							onChange: ( value ) => {
								setAttributes( { isAnimated: value } );
							},
						} ),
						isAnimated &&
							createElement( SelectControl, {
								label: __(
									"Type d'animation",
									'simple-block-animations'
								),
								value: animationType,
								options: [
									{
										label: __(
											'Fondu',
											'simple-block-animations'
										),
										value: 'fade-in',
									},
									{
										label: __(
											'Fondu - Bas vers haut',
											'simple-block-animations'
										),
										value: 'fade-in-up',
									},
									{
										label: __(
											'Fondu - Haut vers bas',
											'simple-block-animations'
										),
										value: 'fade-in-down',
									},
									{
										label: __(
											'Fondu - Gauche vers droite',
											'simple-block-animations'
										),
										value: 'fade-in-left',
									},
									{
										label: __(
											'Fondu - Droite vers gauche',
											'simple-block-animations'
										),
										value: 'fade-in-right',
									},
									{
										label: __(
											'Zoom avant',
											'simple-block-animations'
										),
										value: 'zoom-in',
									},
									{
										label: __(
											'Glissement vers le haut',
											'simple-block-animations'
										),
										value: 'slide-up',
									},
								],
								onChange: ( value ) => {
									setAttributes( { animationType: value } );
								},
							} ),
						isAnimated &&
							createElement( RangeControl, {
								label: __(
									"Durée de l'animation",
									'simple-block-animations'
								),
								value: animationDuration,
								onChange: ( value ) => {
									setAttributes( {
										animationDuration: value,
									} );
								},
								min: 0.2,
								max: 2,
								step: 0.1,
								help: __(
									'Durée en secondes',
									'simple-block-animations'
								),
							} ),
						isAnimated &&
							createElement( RangeControl, {
								label: __(
									"Délai de l'animation",
									'simple-block-animations'
								),
								value: animationDelay,
								onChange: ( value ) => {
									setAttributes( { animationDelay: value } );
								},
								min: 0,
								max: 1,
								step: 0.1,
								help: __(
									'Durée en secondes',
									'simple-block-animations'
								),
							} )
					)
				)
			);
		};
	}, 'withAnimationControls' );

	/**
	 * Add animation classes and styles to all blocks
	 *
	 * @param {Object} props      Extra props applied to the saved element.
	 * @param {Object} blockType  Block type definition.
	 * @param {Object} attributes Block attributes.
	 * @return {Object} Props carrying the animation class and custom properties.
	 */
	function addAnimationClasses( props, blockType, attributes ) {
		// Apply to all blocks
		const { isAnimated, animationType, animationDuration, animationDelay } =
			attributes;

		if ( isAnimated ) {
			const animationClass = `animate-${ animationType }`;

			return {
				...props,
				className: props.className
					? `${ props.className } ${ animationClass }`
					: animationClass,
				style: {
					...props.style,
					'--animation-duration': `${ animationDuration }s`,
					'--animation-delay': `${ animationDelay }s`,
				},
			};
		}

		return props;
	}

	// Apply filters
	addFilter(
		'blocks.registerBlockType',
		'simple_block_animations/animation-attributes',
		addAnimationAttributes
	);
	addFilter(
		'editor.BlockEdit',
		'simple_block_animations/with-animation-controls',
		withAnimationControls
	);
	addFilter(
		'blocks.getSaveContent.extraProps',
		'simple_block_animations/add-animation-classes',
		addAnimationClasses
	);
}
