/*
 * Copyright (c) 2009 the original author or authors
 *
 * Permission is hereby granted to use, modify, and distribute this file
 * in accordance with the terms of the license agreement accompanying it.
 */

package org.robotlegs.utilities.variance.base
{
	import flash.display.DisplayObjectContainer;
	import flash.events.*;
	
	import mx.core.UIComponent;
	
	import org.flexunit.Assert;
	import org.flexunit.async.Async;
	import org.fluint.uiImpersonation.UIImpersonator;
	import org.robotlegs.adapters.*;
	import org.robotlegs.base.*;
	import org.robotlegs.core.*;
	import org.robotlegs.utilities.variance.base.support.*;
	
	public class VariantMediatorMapTests
	{
		public static const TEST_EVENT:String = 'testEvent';
		
		protected var contextView:DisplayObjectContainer;
		protected var eventDispatcher:IEventDispatcher;
		protected var mediatorMap:VariantMediatorMap;
		protected var injector:IInjector;
		protected var reflector:IReflector;
		protected var eventMap:IEventMap;
		
		[BeforeClass]
		public static function runBeforeEntireSuite():void
		{
		}
		
		[AfterClass]
		public static function runAfterEntireSuite():void
		{
		}
		
		[Before(ui)]
		public function runBeforeEachTest():void
		{
			contextView = new TestContextView();
			eventDispatcher = new EventDispatcher();
			injector = new SwiftSuspendersInjector();
			reflector = new SwiftSuspendersReflector();
			mediatorMap = new VariantMediatorMap(contextView, injector, reflector);
			
			injector.mapValue(DisplayObjectContainer, contextView);
			injector.mapValue(IInjector, injector);
			injector.mapValue(IEventDispatcher, eventDispatcher);
			injector.mapValue(IVariantMediatorMap, mediatorMap);
			injector.mapValue(IMediatorMap, new MediatorMap(contextView, injector, reflector));
			
			UIImpersonator.addChild(contextView);
		}
		
		[After(ui)]
		public function runAfterEachTest():void
		{
			UIImpersonator.removeAllChildren();
			injector.unmap(IMediatorMap);
			injector.unmap(IVariantMediatorMap);
		}
		
		[Test]
		public function testInvariantMediatorMapping():void
		{
			mediatorMap.mapMediator(ViewComponent, ViewMediator, false);
			var hasMapping:Boolean = mediatorMap.hasMediatorMapping(ViewComponent, false);
			Assert.assertTrue('VariantMediatorMap has invariantly mapped ' +
							  'ViewMediator for ViewComponent instances', hasMapping);
		}
		
		[Test]
		public function testCovariantMediatorMapping():void
		{
			mediatorMap.mapMediator(ViewComponent, ViewMediator, true);
			var hasMapping:Boolean = mediatorMap.hasMediatorMapping(ViewComponent, true);
			Assert.assertTrue('VariantMediatorMap has covariantly mapped ' +
							  'ViewMediator for ViewComponent instances', hasMapping);
		}
		
		[Test]
		public function testCovariantInterfaceMediatorMapping():void
		{
			mediatorMap.mapMediator(IViewComponent, ViewMediator, true);
			var hasMapping:Boolean = mediatorMap.hasMediatorMapping(IViewComponent, true);
			Assert.assertTrue('VariantMediatorMap has covariantly mapped ' +
							  'ViewMediator for IViewComponent instances', hasMapping);
		}
		
		[Test]
		public function testInvariantMediatorCreation():void
		{
			mediatorMap.mapMediator(ViewComponent, ViewMediator, false);
			var mediators:Vector.<IMediator> = mediatorMap.registerMediators(new ViewComponent());
			Assert.assertTrue('VariantMediatorMap should successfully create a ' +
							  'mediator for the invariant type ViewComponent',
							  mediators.length == 1, mediators[0] is ViewMediator);
		}
		
		[Test]
		public function testCovariantInterfaceMediatorCreation():void
		{
			mediatorMap.mapMediator(IViewComponent, CovariantViewMediator, true);
			var mediators:Vector.<IMediator> = mediatorMap.registerMediators(new ViewComponentImpl());
			Assert.assertTrue('VariantMediatorMap should successfully create a ' +
							  'mediator for the covariant type IViewComponent',
							  mediators.length == 1, mediators[0] is CovariantViewMediator);
		}
		
		[Test]
		public function testCovariantSuperclassMediatorCreation():void
		{
			mediatorMap.mapMediator(ViewComponent, ViewMediator, true);
			var mediators:Vector.<IMediator> = mediatorMap.registerMediators(new ViewComponentAdvanced());
			Assert.assertTrue('VariantMediatorMap should successfully create a ' +
							  'mediator for the covariant type ViewComponent and instance of ' +
							  'ViewComponentAdvanced, a lower type', mediators.length == 1, mediators[0] is ViewMediator);
			
			mediatorMap.mapMediator(UIComponent, UIComponentMediator, true);
			mediators = mediatorMap.registerMediators(new ViewComponent());
			Assert.assertTrue('VariantMediatorMap should successfully create two' +
							  'mediators for an instance of the type ViewComponent', mediators.length == 2);
			
			Assert.assertTrue('VariantMediatorMap should create an instance of' +
							  'ViewMediator as the first mediator for an instance of ' +
							  'ViewComponent', mediators[0] is ViewMediator);
			
			Assert.assertTrue('VariantMediatorMap should create an instance of' +
							  'UIComponentMediator as the second mediator for an instance of' +
							  'ViewComponent, since ViewComponent is a lower type than ' +
							  'UIComponent', mediators[1] is UIComponentMediator);
		}
		
		[Test]
		public function testMXPackagesAreFilteredOutOfAutoMediation():void
		{
			mediatorMap.mapMediator(UIComponent, UIComponentMediator, true);
			var mediators:Vector.<IMediator> = mediatorMap.registerMediators(new UIComponent());
			Assert.assertTrue('VariantMediatorMap should ignore instances of' +
							  'UIComponent because it is in the mx.* package, which is' +
							  'filtered out by default for performance reasons', mediators.length == 0);
		}
		
		[Test]
		public function testMappingAndUnMappingInvariantly():void
		{
			mediatorMap.mapMediator(ViewComponent, ViewMediator, false);
			var hasMapping:Boolean = mediatorMap.hasMediatorMapping(ViewComponent, false);
			Assert.assertTrue('VariantMediatorMap has an invariant mapping for ViewComponent', hasMapping);
			mediatorMap.unmapMediator(ViewComponent, false);
			hasMapping = mediatorMap.hasMediatorMapping(ViewComponent, false);
			Assert.assertTrue('VariantMediatorMap has successfully unmapped its' +
							  'invariant mapping for ViewComponent', hasMapping == false);
		}
		
		[Test]
		public function testMappingAndUnMappingCovariantly():void
		{
			mediatorMap.mapMediator(ViewComponent, ViewMediator, true);
			var hasMapping:Boolean = mediatorMap.hasMediatorMapping(ViewComponent, true);
			Assert.assertTrue('VariantMediatorMap has a covariant mapping for ViewComponent', hasMapping);
			mediatorMap.unmapMediator(ViewComponent, true);
			hasMapping = mediatorMap.hasMediatorMapping(ViewComponent, true);
			Assert.assertTrue('VariantMediatorMap has successfully unmapped its' +
							  'covariant mapping for ViewComponent', hasMapping == false);
		}
		
		[Test(async, timeout='500')]
		public function testInvariantMediatorIsCreatedWhenViewIsAddedToTheDisplayList():void
		{
			mediatorMap.mapMediator(ViewComponent, ViewMediator, false);
			var vc:ViewComponent = new ViewComponent();
			contextView.addChild(vc);
			
			Async.handleEvent(this, contextView, Event.ENTER_FRAME, delayFurther, 500,
							  {
								  dispatcher: contextView,
								  method: checkMediatorCreated,
								  view: vc,
								  mediatorType: ViewMediator
							  });
		}
		
		[Test(async, timeout='500')]
		public function testCovariantMediatorIsCreatedWhenViewIsAddedToTheDisplayList():void
		{
			mediatorMap.mapMediator(ViewComponent, ViewMediator, true);
			var vc:ViewComponent = new ViewComponent();
			contextView.addChild(vc);
			
			Async.handleEvent(this, contextView, Event.ENTER_FRAME, delayFurther, 500,
							  {
								  dispatcher: contextView,
								  method: checkMediatorCreated,
								  view: vc,
								  mediatorType: ViewMediator
							  });
		}
		
		[Test(async, timeout='500')]
		public function testCovariantMediatorIsCreatedWhenSubclassOfViewIsAddedToTheDisplayList():void
		{
			mediatorMap.mapMediator(ViewComponent, ViewMediator, true);
			var vc:ViewComponent = new ViewComponentAdvanced();
			contextView.addChild(vc);
			
			Async.handleEvent(this, contextView, Event.ENTER_FRAME, delayFurther, 500,
							  {
								  dispatcher: contextView,
								  method: checkMediatorCreated,
								  view: vc,
								  mediatorType: ViewMediator
							  });
		}
		
		[Test(async, timeout='500')]
		public function testCovariantMediatorIsCreatedWhenViewInterfaceIsAddedToTheDisplayList():void
		{
			mediatorMap.mapMediator(IViewComponent, CovariantViewMediator, true);
			var vc:ViewComponentImpl = new ViewComponentImpl();
			contextView.addChild(vc);
			
			Async.handleEvent(this, contextView, Event.ENTER_FRAME, delayFurther, 500,
							  {
								  dispatcher: contextView,
								  method: checkMediatorCreated,
								  view: vc,
								  mediatorType: CovariantViewMediator
							  });
		}
		
		[Test(async, timeout='500')]
		public function testInvariantMediatorIsDestroyedWhenViewIsRemovedFromTheDisplayList():void
		{
			mediatorMap.enabled = false;
			
			mediatorMap.mapMediator(ViewComponent, ViewMediator, true);
			var vc:ViewComponent = new ViewComponent();
			contextView.addChild(vc);
			mediatorMap.registerMediators(vc);
			
			mediatorMap.enabled = true;
			
			contextView.removeChild(vc);
			
			Async.handleEvent(this, contextView, Event.ENTER_FRAME, delayFurther, 500,
							  {
								  dispatcher: contextView,
								  method: checkMediatorDestroyed,
								  view: vc
							  });
		}
		
		[Test(async, timeout='500')]
		public function testCovariantMediatorIsDestroyedWhenViewIsRemovedFromTheDisplayList():void
		{
			mediatorMap.enabled = false;
			
			mediatorMap.mapMediator(ViewComponent, ViewMediator, false);
			var vc:ViewComponent = new ViewComponent();
			contextView.addChild(vc);
			mediatorMap.registerMediators(vc);
			
			mediatorMap.enabled = true;
			
			contextView.removeChild(vc);
			
			Async.handleEvent(this, contextView, Event.ENTER_FRAME, delayFurther, 500,
							  {
								  dispatcher: contextView,
								  method: checkMediatorDestroyed,
								  view: vc
							  });
		}
		
		[Test(async, timeout='500')]
		public function testCovariantMediatorIsDestroyedWhenSubclassOfViewIsRemovedFromTheDisplayList():void
		{
			mediatorMap.enabled = false;
			
			mediatorMap.mapMediator(ViewComponent, ViewMediator, false);
			var vc:ViewComponent = new ViewComponentAdvanced();
			contextView.addChild(vc);
			mediatorMap.registerMediators(vc);
			
			mediatorMap.enabled = true;
			
			contextView.removeChild(vc);
			
			Async.handleEvent(this, contextView, Event.ENTER_FRAME, delayFurther, 500,
							  {
								  dispatcher: contextView,
								  method: checkMediatorDestroyed,
								  view: vc
							  });
		}
		
		[Test(async, timeout='500')]
		public function testCovariantMediatorIsDestroyedWhenViewInterfaceIsRemovedFromTheDisplayList():void
		{
			mediatorMap.enabled = false;
			
			mediatorMap.mapMediator(IViewComponent, CovariantViewMediator, false);
			var vc:ViewComponentImpl = new ViewComponentImpl();
			contextView.addChild(vc);
			mediatorMap.registerMediators(vc);
			
			mediatorMap.enabled = true;
			
			contextView.removeChild(vc);
			
			Async.handleEvent(this, contextView, Event.ENTER_FRAME, delayFurther, 500,
							  {
								  dispatcher: contextView,
								  method: checkMediatorDestroyed,
								  view: vc
							  });
		}
		
		private function checkMediatorCreated(event:Event, data:Object):void
		{
			var mediators:Vector.<IMediator> = mediatorMap.getMediators(data.view);
			Assert.assertTrue('VariantMediatorMap should successfully create a ' +
							  'mediator for the type "ViewComponent"',
							  mediators.length == 1, mediators[0] is data.mediatorType);
		}
		
		private function checkMediatorDestroyed(event:Event, data:Object):void
		{
			var mediators:Vector.<IMediator> = mediatorMap.getMediators(data.view);
			Assert.assertTrue('VariantMediatorMap should successfully create a ' +
							  'mediator for the type "ViewComponent"',
							  mediators.length == 0);
		}
		
		private function delayFurther(event:Event, data:Object):void
		{
			Async.handleEvent(this, data.dispatcher, Event.ENTER_FRAME, data.method, 500, data);
			delete data['dispatcher'];
			delete data['method'];
		}
	}
}
