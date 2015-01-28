# LOVE API Coverage

This is a pretty sad state of affairs! Please help!

* missing luasocket and lua-enet!
* love
   * missing some callbacks
   * love.focus
   * love.mousefocus
   * love.mousepressed & love.mousereleased
      * stubbed, need to fire events
   * love.resize
   * love.run
      * hate init needs some restructuring
   * love.textinput
   * love.threaderror
      * depends on hate.thread
   * love.visible
   * haven't touched joysticks! will need:
      * love.gamepadaxis
      * love.gamepadpressed
      * love.gamepadreleased
      * love.joystickadded
      * love.joystickaxis
      * love.joystickhat
      * love.joystickpressed
      * love.joystickreleased
      * love.joystickremoved

## Not yet started

* love.audio *not yet started*
* love.font *not yet started*
* love.image *not yet started*
* love.joystick *not yet started*
* love.keyboard *not yet started*
* love.math *not yet started*
* love.mouse *not yet started*
* love.physics *not yet started*
* love.sound *not yet started*
* love.thread *not yet started*

## Started

* love.keypressed & love.keyreleased
  * Missing many key codes.
* love.errhand **started**
  * Missing too many features to implement 100%, but the callback is done.
* love.event **started**
* love.filesystem **started**
* love.graphics **started**
* love.window **started**

## Complete

* love.system **complete**
* love.timer **complete**
