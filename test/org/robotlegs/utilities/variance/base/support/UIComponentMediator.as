package org.robotlegs.utilities.variance.base.support
{
	import mx.core.UIComponent;
	
	import org.robotlegs.mvcs.Mediator;
	
	public class UIComponentMediator extends Mediator
	{
		[Inject]
		public var component:UIComponent;
		
		public function UIComponentMediator()
		{
			super();
		}
	}
}