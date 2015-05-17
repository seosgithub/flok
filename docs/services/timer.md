#Timer service
This service manages the `int_timer` function (which is a little different than how most modules work). When an `int_timer` request
comes in, the timer service dispatches it to an apprpriate controller event handler.

Timer service mantains an `timer_evt` which contains an array of arrays for interval timers that will be called (recurring) periodically.
The elements of `timer_evt` are an array with the following information: `[tps, base_pointer, event_name]`.  When `int_timer` is called,
it will send events to all entries in `timer_evt` which have a `ticks` that is a modulo of `ttick`; the global tick counter.

###Info to start a request
```js
var info = {
  ticks: 4,
}
```
`ticks` the number of ticks to wait between fires.

When you receive a request back, you will receive 
```js
{
}
```
