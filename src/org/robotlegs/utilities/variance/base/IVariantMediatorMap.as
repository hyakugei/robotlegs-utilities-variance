package org.robotlegs.utilities.variance.base
{
	import org.robotlegs.core.IMediator;
	
	/**
	 * A map of view types to mediator types. Mapping can be covariant or
	 * invariant, with the default being covariant.
	 */
	public interface IVariantMediatorMap
	{
		/**
		 * Maps a view to be automatically mediated by an IMediator type.
		 * 
		 * In invariant mediation, the type of component must match exactly to
		 * the type being mediated. This is invariant because only instances
		 * of the exact <code>viewType</code> will cause the
		 * <code>IVariantMediatorMap</code> to create the mapped mediator.
		 * 
		 * In covariant mediation, if the component extends or implements any of
		 * the mapped <code>viewType</code>s, an instance of the mapped mediator
		 * will be instantiated and associated with the component. This is
		 * covariant, because a higher level generic type (beit interface or
		 * superclass) maps to the lower-level concrete implementation.
		 * 
		 * The default is covariance.
		 */
		function mapMediator(viewType:Class, mediatorType:Class, covariant:Boolean = true):void;
		
		/**
		 * Checks if the IVariantMediatorMap has a covariant or invariant typing
		 * for a given <code>viewType</code>.
		 * 
		 * @returns true if there is a mapping, false if there isn't.
		 */
		function hasMediatorMapping(viewType:Class, covariant:Boolean = true):Boolean;
		
		/**
		 * Unmaps the given viewType with the associated covariance flag from
		 * the <code>IVariantMediatorMap</code>
		 */
		function unmapMediator(viewType:Class, covariant:Boolean = true):void;
		
		/**
		 * Ensures registration of all the mediators for the given
		 * <code>viewComponent</code> instance.
		 * 
		 * @returns A Vector of all the IMediator instances associated with the
		 * <code>viewComponent</code> instance.
		 */
		function registerMediators(viewComponent:Object):Vector.<IMediator>;
		
		/**
		 * Gets all the currently registered mediators for the given
		 * <code>viewComponent</code> instance.
		 * 
		 * @returns A Vector of all the IMediator instances associated with the
		 * <code>viewComponent</code>.
		 */
		function getMediators(viewComponent:Object):Vector.<IMediator>;
		
		/**
		 * Ensures removal of all the mediators for the given
		 * <code>viewComponent</code> instance.
		 * 
		 * @returns A Vector of all the IMediator instances that were
		 * de-associated with the <code>viewComponent</code> instance.
		 */
		function removeMediators(viewComponent:Object):Vector.<IMediator>;
	}
}