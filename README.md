# acid test

generative acid basslines.


![meme](/img/meme.png)

been listening to acid music and thinking about markov chains. I previously made a [jazz piano accompaniment with markov chains](https://github.com/schollz/pianoai) and saw acid house as an interesting genre to also try applying stateless logic for generating believable sequences. whether this is believable "acid" music or not...debatable.



## Requirements

- norns

## Documentation


the script essentially plays generatively by generating 16-note sequences based on 9 markov chains. the notes generated will either play in the build-in 303-style engine or can be output to the midi synth of your choice.


this script assumes you have some basic understanding for a markov chain! you can get a lot of info and examples about markov chains [here](https://en.wikipedia.org/wiki/Markov_chain#Examples). feel free to ask questions.

the transitions in each markov chain are determined at each step in the sequence based on probabilities that you can control. to control the probabilities you can use E1 to select an property and use E2 to select a transition in that property. then use E3 to modifty the probability of that transition. the combination of these 9 properties are then combined to generate the sequence:

### accent

transitions between "no" and "yes", at which the velocity will be increased slightly for that note.

![accent](/img/accent.png)

### slide

transitions between "no" and "yes", at which the portamento is increased.

![slide](/img/slide.png)

### bass or lead

this property transitions between "bass" and "lead". the generator actually generates 32 notes - 16 bass notes and 16 lead notes, but will only select either based on the state of this property.

![bassorlead](/img/bassorlead.png)

### bass coef+mult

the bass and lead both use two properties to generate the note. the starting note of each sequence is the base note defined in the parameters. that starting note is then increased by `coef x mult` at each step in the sequence. for example, if the `coef` state is `2` and the `mult` is `-1` then the sequence will transition `-2` notes in the scale.


![bassorlead](/img/basscoef.png)

![bassorlead](/img/bassmult.png)


### lead coef+mult

the lead coef+mult works the same way as the bass coef+mult, but only affects the lead notes.

![bassorlead](/img/leadcoef.png)

![bassorlead](/img/leadmult.png)

### bass / lead note

the legato of the note will be determined by the "bass note"  property (for bass notes) or the "lead note" property (for lead notes). if the state is "rest" then no note will be played, and any current note will be stopped. if the state is "new" then the current note will be stopped and a new note will be played. if the state is "hold" and the new note is the same as the last note, then there will be no gate, it will simply continue the note. if the new note is not the same and there is a slide, then portamento will be applied.

![bassnote](/img/bassnote.png)

![leadnote](/img/leadnote.png)

## TODO:

- allow setting portamento cc

## Install

install using with

```
;install https://github.com/schollz/acid-test
```

