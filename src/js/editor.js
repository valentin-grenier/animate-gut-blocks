import { __ } from '@wordpress/i18n';
import { addFilter } from '@wordpress/hooks';
import { createHigherOrderComponent } from '@wordpress/compose';
import { createElement, Fragment } from '@wordpress/element';
import { InspectorControls } from '@wordpress/block-editor';
import { PanelBody, ToggleControl, SelectControl, RangeControl } from '@wordpress/components';
import '../scss/editor.scss';

// Prevent multiple executions
if (!window.simpleBlockAnimationsAttributesFiltersAdded) {
	window.simpleBlockAnimationsAttributesFiltersAdded = true;

	/**
	 * Add animation attributes to all blocks
	 */
	function addAnimationAttributes(settings, name) {
		// Apply to all blocks
		return {
			...settings,
			attributes: {
				...settings.attributes,
				isAnimated: {
					type: 'boolean',
					default: false,
				},
				animationType: {
					type: 'string',
					default: 'fade-in',
				},
				animationDuration: {
					type: 'number',
					default: 0.6,
				},
				animationDelay: {
					type: 'number',
					default: 0,
				},
			},
		};
	}

	/**
	 * Add animation controls to all blocks
	 */
	const withAnimationControls = createHigherOrderComponent((BlockEdit) => {
		return (props) => {
			const { name, attributes, setAttributes } = props;
			const { isAnimated, animationType, animationDuration, animationDelay } = attributes;

			// Skip if attributes are not available (edge case for some blocks)
			if (!attributes || typeof isAnimated === 'undefined') {
				return createElement(BlockEdit, props);
			}

			return createElement(
				Fragment,
				null,
				createElement(BlockEdit, props),
				createElement(
					InspectorControls,
					{ group: 'settings' },
					createElement(
						PanelBody,
						{
							title: __('Animations', 'simple_block_animations'),
							initialOpen: true,
						},
					createElement(ToggleControl, {
						label: __('Animer le bloc', 'simple_block_animations'),
						checked: isAnimated,
							onChange: (value) => {
								setAttributes({ isAnimated: value });
							},
						}),
						isAnimated &&
						createElement(SelectControl, {
							label: __("Type d'animation", 'simple_block_animations'),
							value: animationType,
							options: [
								{ label: __('Fondu', 'simple_block_animations'), value: 'fade-in' },
								{ label: __('Fondu - Bas vers haut', 'simple_block_animations'), value: 'fade-in-up' },
								{ label: __('Fondu - Haut vers bas', 'simple_block_animations'), value: 'fade-in-down' },
								{ label: __('Fondu - Gauche vers droite', 'simple_block_animations'), value: 'fade-in-left' },
								{ label: __('Fondu - Droite vers gauche', 'simple_block_animations'), value: 'fade-in-right' },
							],
								onChange: (value) => {
									setAttributes({ animationType: value });
								},
							}),
						isAnimated &&
						createElement(RangeControl, {
							label: __("Durée de l'animation", 'simple_block_animations'),
							value: animationDuration,
							onChange: (value) => {
								setAttributes({ animationDuration: value });
							},
							min: 0.2,
							max: 2,
							step: 0.1,
							help: __('Durée en secondes', 'simple_block_animations'),
							}),
						isAnimated &&
						createElement(RangeControl, {
							label: __("Délai de l'animation", 'simple_block_animations'),
							value: animationDelay,
							onChange: (value) => {
								setAttributes({ animationDelay: value });
							},
							min: 0,
							max: 1,
							step: 0.1,
							help: __('Durée en secondes', 'simple_block_animations'),
							})
					)
				)
			);
		};
	}, 'withAnimationControls');

	/**
	 * Add animation classes and styles to all blocks
	 */
	function addAnimationClasses(props, blockType, attributes) {
		// Apply to all blocks
		const { isAnimated, animationType, animationDuration, animationDelay } = attributes;

		if (isAnimated) {
			const animationClass = `animate-${animationType}`;

			return {
				...props,
				className: props.className ? `${props.className} ${animationClass}` : animationClass,
				style: {
					...props.style,
					'--animation-duration': `${animationDuration}s`,
					'--animation-delay': `${animationDelay}s`,
				},
			};
		}

		return props;
	}

	// Apply filters
	addFilter('blocks.registerBlockType', 'simple_block_animations/animation-attributes', addAnimationAttributes);
	addFilter('editor.BlockEdit', 'simple_block_animations/with-animation-controls', withAnimationControls);
	addFilter('blocks.getSaveContent.extraProps', 'simple_block_animations/add-animation-classes', addAnimationClasses);
}
