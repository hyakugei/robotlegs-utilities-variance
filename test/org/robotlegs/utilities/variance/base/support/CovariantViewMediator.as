package org.robotlegs.utilities.variance.base.support
{
	import org.robotlegs.mvcs.Mediator;
	
	public class CovariantViewMediator extends Mediator
	{
		[Inject]
		public var view:IViewComponent;
		
		public function CovariantViewMediator()
		{
			super();
		}
		
		override public function onRegister():void
		{
			
		}
		
		override public function onRemove():void
		{
			
		}
	}
}