package org.robotlegs.utilities.variance.base
{
	import flash.display.*;
	import flash.events.Event;
	import flash.utils.Dictionary;
	
	import org.robotlegs.base.*;
	import org.robotlegs.core.*;
	
	/**
	 * @inheritDoc
	 */
	public class VariantMediatorMap extends ViewMapBase implements IVariantMediatorMap, IPackageFilters
	{
		public function VariantMediatorMap(contextView:DisplayObjectContainer,
										   injector:IInjector,
										   reflector:IReflector,
										   filter:IPackageFilters = null)
		{
			viewListenerCount = 1;
			
			super(contextView, injector);
			
			this.reflector = reflector;
			this.filter = filter || new PackageFilters(reflector);
			
			registerPackageFilter('flash.*');
			registerPackageFilter('mx.*');
		}
		
		protected var reflector:IReflector;
		protected const mediatorClassMap:Dictionary = new Dictionary(false);
		protected const mediatorMap:Object = {};
		
		/**
		 * @inheritDoc
		 */
		public function mapMediator(viewType:Class, mediatorType:Class, covariant:Boolean = true):void
		{
			const variance:int = int(covariant);
			
			if(!(viewType in mediatorClassMap))
			{
				mediatorClassMap[viewType] = [];
			}
			
			if(!mediatorClassMap[viewType][variance])
			{
				mediatorClassMap[viewType][variance] = mediatorType;
			}
		}
		
		/**
		 * @inheritDoc
		 */
		public function hasMediatorMapping(viewType:Class, covariant:Boolean = true):Boolean
		{
			return (viewType in mediatorClassMap) && Boolean(mediatorClassMap[viewType][int(covariant)]);
		}
		
		/**
		 * @inheritDoc
		 */
		public function unmapMediator(viewType:Class, covariant:Boolean = true):void
		{
			if(!hasMediatorMapping(viewType, covariant))
			{
				return;
			}
			
			const mediatorType:Class = mediatorClassMap[viewType][int(covariant)];
			if(mediatorClassMap[viewType][int(!covariant)])
			{
				mediatorClassMap[viewType][int(covariant)] = null;
			}
			else
			{
				delete mediatorClassMap[viewType];
			}
		}
		
		/**
		 * @inheritDoc
		 */
		public function registerMediators(viewComponent:Object):Vector.<IMediator>
		{
			if(!applyFilters(viewComponent))
			{
				return new <IMediator>[];
			}
			
			var viewTypes:Vector.<Class> = retrieveViewTypes(viewComponent);
			var mediatorTypes:Vector.<Class> = retrieveMediatorClasses(viewComponent);
			var mediatorNames:Vector.<String> = retrieveMediatorNames(viewComponent, mediatorTypes);
			
			var mediators:Vector.<IMediator> = new <IMediator>[];
			
			mediatorNames.forEach(function(name:String, i:int, v:Vector.<String>):void{
				if(name in mediatorMap)
				{
					mediators.push(mediatorMap[name]);
					return;
				}
				
				var mediatorType:Class = mediatorTypes[i];
				
				viewTypes.forEach(function(viewType:Class, ... args):void{
					injector.mapValue(viewType, viewComponent);
				});
				
				var mediator:IMediator = injector.instantiate(mediatorType) as IMediator;
				
				viewTypes.forEach(function(viewType:Class, ... args):void{
					injector.unmap(viewType);
				});
				
				mediator.setViewComponent(viewComponent);
				mediator.preRegister();
				
				mediators.push(mediatorMap[name] = mediator);
			});
			
			return mediators;
		}
		
		/**
		 * @inheritDoc
		 */
		public function getMediators(viewComponent:Object):Vector.<IMediator>
		{
			if(!applyFilters(viewComponent))
			{
				return new <IMediator>[];
			}
			
			var mediatorNames:Vector.<String> =
				retrieveMediatorNames(viewComponent, retrieveMediatorClasses(viewComponent));
			
			var mediators:Vector.<IMediator> = new <IMediator>[];
			
			mediatorNames.forEach(function(name:String, ... args):void{
				if(!(name in mediatorMap))
					return;
				
				mediators.push(mediatorMap[name]);
			});
			
			return mediators;
		}
		
		/**
		 * @inheritDoc
		 */
		public function removeMediators(viewComponent:Object):Vector.<IMediator>
		{
			if(!applyFilters(viewComponent))
			{
				return new <IMediator>[];
			}
			
			var mediatorNames:Vector.<String> =
				retrieveMediatorNames(viewComponent, retrieveMediatorClasses(viewComponent));
			
			var mediators:Vector.<IMediator> = new <IMediator>[];
			
			mediatorNames.forEach(function(name:String, ... args):void{
				if(!(name in mediatorMap))
					return;
				
				var mediator:IMediator = mediatorMap[name];
				mediator.preRemove();
				mediator.setViewComponent(null);
				delete mediatorMap[name];
				mediators.push(mediator);
			});
			
			return mediators;
		}
		
		/**
		 * Returns a Vector of Classes that represent all the mapped
		 * <code>viewType</code>s that this <code>viewComponent</code> instance
		 * matches.
		 * 
		 * @private
		 */
		protected function retrieveViewTypes(viewComponent:Object):Vector.<Class>
		{
			const classes:Vector.<Class> = new <Class>[];
			var viewType:* = reflector.getClass(viewComponent);
			
			if(hasMediatorMapping(viewType, false))
			{
				classes.push(viewType);
			}
			for(viewType in mediatorClassMap)
			{
				if(viewComponent is viewType && hasMediatorMapping(viewType, true))
				{
					classes.push(viewType);
				}
			}
			
			return classes;
		}
		
		/**
		 * Returns a Vector of Classes that represent all the mapped
		 * <code>mediatorType</code>s that this <code>viewComponent</code>
		 * instance matches.
		 */
		protected function retrieveMediatorClasses(viewComponent:Object):Vector.<Class>
		{
			const classes:Vector.<Class> = new <Class>[];
			var viewType:* = reflector.getClass(viewComponent);
			
			//Catch invariant type.
			if(hasMediatorMapping(viewType, false))
			{
				classes.push(mediatorClassMap[viewType][int(false)]);
			}
			//Check for covariance.
			for(viewType in mediatorClassMap)
			{
				if(viewComponent is viewType && hasMediatorMapping(viewType, true))
				{
					classes.push(mediatorClassMap[viewType][int(true)]);
				}
			}
			
			return classes;
		}
		
		/**
		 * Returns a Vector of unique String IDs from a combination of the given
		 * <code>viewComponent</code> instance and each mediator type.
		 */
		protected function retrieveMediatorNames(viewComponent:Object,
												 mediatorTypes:Vector.<Class>):Vector.<String>
		{
			var mediatorNames:Vector.<String> = new <String>[];
			
			mediatorTypes.forEach(function(type:Class, ... args):void{
				mediatorNames.push(createMediatorName(viewComponent, type))
			});
			
			return mediatorNames;
		}
		
		/**
		 * Creates a semi-unique key from the combination of the given
		 * <code>viewComponent</code> instance and the mediatorType.
		 * 
		 * Note: It is feasible that two <code>viewComponent</code>s of the same
		 * Class type can exist at the same nestLevel and with the same name
		 * as each other. It might be worth revisiting this later to harden the
		 * uniqueness guaranteed by this function.
		 */
		protected function createMediatorName(viewComponent:Object, mediatorType:Class):String
		{
			if(!viewComponent)
				return 'invalid mediator name';
			
			var viewName:String = reflector.getFQCN(viewComponent, true);
			
			if('name' in viewComponent)
				viewName += '#' + viewComponent['name'];
			
			return reflector.getFQCN(mediatorType, true) + " : " + viewName;
		}
		
		////
		// Stubbed IPackageFilters impl. via the Visitor pattern.
		////
		
		protected var filter:IPackageFilters;
		
		/**
		 * @inheritDoc
		 */
		public function registerPackageFilter(packageFilter:String):void
		{
			filter.registerPackageFilter(packageFilter);
		}
		
		/**
		 * @inheritDoc
		 */
		public function removePackageFilter(packageFilter:String):void
		{
			filter.removePackageFilter(packageFilter);
		}
		
		/**
		 * @inheritDoc
		 */
		public function applyFilters(viewComponent:Object):Boolean
		{
			return filter.applyFilters(viewComponent);
		}
		
		override public function set enabled(value:Boolean):void
		{
			viewListenerCount = value ? 1 : 0;
			
			super.enabled = value;
		}
		
		////
		// Display-list queueing and invalidation logic.
		////
		
		override protected function addListeners():void
		{
			if(!contextView)
				return;
			
			contextView.addEventListener(Event.ADDED_TO_STAGE, onViewAdded, useCapture, 0, true);
			contextView.addEventListener(Event.REMOVED_FROM_STAGE, onViewRemoved, useCapture, 0, true);
		}
		
		override protected function removeListeners():void
		{
			if(!contextView)
				return;
			
			contextView.removeEventListener(Event.ADDED_TO_STAGE, onViewAdded, useCapture);
			contextView.removeEventListener(Event.REMOVED_FROM_STAGE, onViewRemoved, useCapture);
		}
		
		protected const addedViews:Dictionary = new Dictionary(false);
		protected const removedViews:Dictionary = new Dictionary(false);
		
		override protected function onViewAdded(e:Event):void
		{
			var view:Object = e.target;
			addedViews[view] = true;
			
			if(view in removedViews)
				delete removedViews[view];
			
			invalidateFrame();
		}
		
		protected function onViewRemoved(e:Event):void
		{
			var view:Object = e.target;
			removedViews[view] = true;
			
			if(view in addedViews)
				delete addedViews[view];
			
			invalidateFrame();
		}
		
		protected const frameProvider:Shape = new Shape();
		
		protected function invalidateFrame():void
		{
			frameProvider.addEventListener(Event.ENTER_FRAME, onEnterFrame);
		}
		
		protected function onEnterFrame(event:Event):void
		{
			frameProvider.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
			
			var view:Object;
			
			for(view in addedViews)
				registerMediators(view);
			
			for(view in removedViews)
				removeMediators(view);
		}
	}
}
import flash.utils.Dictionary;

import org.robotlegs.core.IReflector;
import org.robotlegs.utilities.variance.base.IPackageFilters;

internal class PackageFilters implements IPackageFilters
{
	public function PackageFilters(reflector:IReflector)
	{
		this.reflector = reflector;
	}
	
	private var reflector:IReflector;
	private const packageFiltersMap:Dictionary = new Dictionary(false);
	
	public function registerPackageFilter(packageFilter:String):void
	{
		packageFiltersMap[packageFilter] =
			new RegExp('^' + packageFilter.replace(/\./g, '\\$&').replace(/\*/g, '.+') + '::');
	}
	
	public function removePackageFilter(packageFilter:String):void
	{
		delete packageFiltersMap[packageFilter];
	}
	
	public function applyFilters(viewComponent:Object):Boolean
	{
		for each(var filter:RegExp in packageFiltersMap)
		{
			if(filter.test(reflector.getFQCN(viewComponent.constructor)))
			{
				return false;
			}
		}
		
		return true;
	}
}