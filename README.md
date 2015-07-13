# gitstat.rb

Fairly simple stats for your git repos. Works with whitelists. The idea is to find out the truth: whitelist files that were written by hand :smirk:.

## Installation

```shell
# git clone https://github.com/etm/gitstats.rb.git
# cp gitstats.rb/gitstats.rb ~/bin
```
## Usage

All files generate by ***gitstats.rb*** will always appear in your repositories home directory (the one that holds .git).

1. go to the git repository you want to create stats for
2. run ```gitstats.rb```
3. look at ```.stats```
3. delete lines from ```.whitelist```
4. tweak your ```.statsauthors```:
  * remove authors to remove their contribution from stats
  * if the same author commited under different names, just indent his alias names under the name you want him to appear in the stats
5. repeat steps 2. - 5. until you are happy

## License

All code in this package is provided under the LGPL license.
Please read the file COPYING.
