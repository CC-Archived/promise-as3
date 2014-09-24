
package com.codecatalyst.promise
{

public class TimeOutError extends Error
{
  public function TimeOutError( message:String = null)
  {
    super( message ? message : "Promise timed out." );
  }
}
}
