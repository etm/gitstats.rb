# gitstat.rb

Fairly simple stats for your git repos. Works with whitelists. The idea is to find out the truth: whitelist files that were written by hand :smirk:. ***gitstat.rb*** has no parameters, just run it anywhere in a git repo. Its results can be inspected in the repositories' root directory.

## Installation

```shell
# git clone https://github.com/etm/gitstats.rb.git
# cp gitstats.rb/gitstats.rb ~/bin
```
## Usage

All files generate by ***gitstats.rb*** will always appear in your repositories' root directory (the one that holds .git).

1. go to the git repository you want to create stats for
2. run ```gitstats.rb```
3. look at ```.stats```
3. delete lines from ```.whitelist```
4. tweak your ```.statsauthors```:
  * remove authors to remove their contribution from stats
  * if the same author commited under different names, just indent his alias names under the name you want him to appear in the stats
5. repeat steps 2. - 5. until you are happy

## Tips

When ```.whitelist``` changes, because of new files in a new commit, a ```.whitelist.old``` is created. Compare these two to find out which files have been added.'

The file ```.statsrun``` holds the hash from the commit when the stats tool has
been run last. This is the basis for deciding which files are to be added to
the whitelist.

## Planned features

* effort by month, weekday (priority 1)
* create a filtered custom log as input for gource (priority 1)
* results for date ranges (priority 2)
* create graphs, probably with chartkick, thus result will be html+js (priority 3)

## License

All code in this package is provided under the LGPL license.
Please read the file COPYING.
