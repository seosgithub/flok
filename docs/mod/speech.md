#Speech (speech.js)
There is a software-simulation of the `speech` module. To enable it, put `speech_sim` in the `enable` section of your config file. The speech sim will replicate the rate at which speech progresses but will not produce audio (obviously).

###Client interface
`if_speech_say(text)` - Start speaking this text. Multiple things will never be queued.
`if_speech_cancel()` - Stop any speaking in progress; if there is no speaking then nothing should happend

###Kernel interrupts
`int_speech_cancelled()` - The speech was cancelled
`int_speech_finished()` - The speech completed succesfully
`int_speech_started()` - The speech has started
`int_will_speak_range(offset, count)` - The speech is in the process of talking over a range of the text