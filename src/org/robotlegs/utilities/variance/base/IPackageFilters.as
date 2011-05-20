package org.robotlegs.utilities.variance.base
{
	/**
	 * An interface which defines an object that can filter an instance based
	 * on a list of String package names.
	 */
	public interface IPackageFilters
	{
		/**
		 * Registers a package name to check against in <code>applyFilters()</code>.
		 * 
		 * @see IPackageFilters#applyFilters
		 */
		function registerPackageFilter(packageFilter:String):void;
		
		/**
		 * Removes a package name from the list of packages checked in
		 * <code>applyFilters()</code>.
		 * 
		 * @see IPackageFilters#applyFilters
		 */
		function removePackageFilter(packageFilter:String):void;
		
		/**
		 * Filters the given <code>instance</code> against every registered
		 * package name.
		 * 
		 * @returns false if the instance exists in one of the registered
		 * package names, true if it does not.
		 */
		function applyFilters(instance:Object):Boolean;
	}
}