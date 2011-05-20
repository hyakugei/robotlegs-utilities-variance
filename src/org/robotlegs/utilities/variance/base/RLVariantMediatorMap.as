package org.robotlegs.utilities.variance.base
{
	import flash.display.*;
	import flash.events.Event;
	import flash.utils.*;
	
	import org.robotlegs.core.*;
	
	/**
	 * A VariantMediatorMap implementation of IMediatorMap for backwards
	 * compatibility with existing robotlegs code. IMediatorMap is implicitly
	 * invariant, so every function from IMediatorMap translates to its
	 * invariant counterpart from IVariantMediatorMap.
	 */
	public class RLVariantMediatorMap extends VariantMediatorMap implements IMediatorMap
	{
		public function RLVariantMediatorMap(contextView:DisplayObjectContainer,
											 injector:IInjector,
											 reflector:IReflector,
											 filter:IPackageFilters = null)
		{
			super(contextView, injector, reflector, filter);
		}
		
		protected const addExceptions:Dictionary = new Dictionary(false);
		protected const removeExceptions:Dictionary = new Dictionary(false);
		
		public function mapView(viewClassOrName:*,
								mediatorClass:Class,
								injectViewAs:* = null,
								autoCreate:Boolean = true,
								autoRemove:Boolean = true):void
		{
			viewClassOrName = reflector.getClass(viewClassOrName);
			
			mapMediator(viewClassOrName, mediatorClass, false);
			
			if(injectViewAs != null)
			{
				if(injectViewAs is Class)
				{
					injectViewAs = [injectViewAs];
				}
				
				if(injectViewAs is Array)
				{
					for each(var type:Class in injectViewAs)
					{
						mapMediator(type, mediatorClass, true);
					}
				}
			}
			
			if(!autoCreate)
			{
				addExceptions[viewClassOrName] = true;
			}
			
			if(!autoRemove)
			{
				removeExceptions[viewClassOrName] = true;
			}
			
			if(autoCreate && contextView && contextView is viewClassOrName)
			{
				registerMediators(contextView);
			}
		}
		
		public function unmapView(viewClassOrName:*):void
		{
			viewClassOrName = reflector.getClass(viewClassOrName);
			
			unmapMediator(viewClassOrName, false);
		}
		
		public function createMediator(viewComponent:Object):IMediator
		{
			var mediators:Vector.<IMediator> = registerMediators(viewComponent);
			return mediators.length ? mediators[0] : null
		}
		
		public function registerMediator(viewComponent:Object, mediator:IMediator):void
		{
			mediatorMap[createMediatorName(viewComponent, reflector.getClass(mediator))] = mediator;
		}
		
		public function removeMediator(mediator:IMediator):IMediator
		{
			var mediatorName:String = createMediatorName(mediator.getViewComponent(), reflector.getClass(mediator));
			if(mediatorName in mediatorMap)
			{
				var mediator:IMediator = mediatorMap[mediatorName];
				delete mediatorMap[mediatorName];
				return mediator;
			}
			
			return null;
		}
		
		public function removeMediatorByView(viewComponent:Object):IMediator
		{
			var mediators:Vector.<IMediator> = getMediators(viewComponent);
			if(mediators.length > 0)
			{
				removeMediator(mediators[0]);
				return mediators[0];
			}
			
			return null;
		}
		
		public function retrieveMediator(viewComponent:Object):IMediator
		{
			var mediators:Vector.<IMediator> = getMediators(viewComponent);
			return mediators.length ? mediators[0] : null;
		}
		
		public function hasMapping(viewClassOrName:*):Boolean
		{
			return hasMediatorMapping(viewClassOrName, false);
		}
		
		public function hasMediator(mediator:IMediator):Boolean
		{
			var mediatorName:String = createMediatorName(mediator.getViewComponent(), reflector.getClass(mediator));
			return mediatorName in mediatorMap;
		}
		
		public function hasMediatorForView(viewComponent:Object):Boolean
		{
			return getMediators(viewComponent).length > 0;
		}
		
		override protected function onViewAdded(e:Event):void
		{
			var view:Object = e.target;
			var type:Class = reflector.getClass(view);
			
			// This is a hack... RL's MediatorMap implementation creates the 
			// Mediator as soon as a view is added to the display list. It should
			// queue and invalidate instead. I'll concede for the sake of
			// backwards compatibility.
			
			if(view in removedViews)
				delete removedViews[view];
			
			if(type in addExceptions)
				return;
			
			registerMediators(view);
//			super.onViewAdded(e);
		}
		
		override protected function onViewRemoved(e:Event):void
		{
			var view:Object = e.target;
			var type:Class = reflector.getClass(view);
			
			if(view in addedViews)
				delete addedViews[view];
			
			if(type in removeExceptions)
				return;
			
			super.onViewRemoved(e);
		}
	}
}