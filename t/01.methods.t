use Test::More qw/no_plan/;
use Text::KuaiWiki;
use Encode;

can_ok(Text::KuaiWiki,(build_li));

my @data = qw/hoge fuga liliugaeo gibb/;
is Text::KuaiWiki::build_li(@data), <<'_HERE_';
<li>hoge</li>
<li>fuga</li>
<li>liliugaeo</li>
<li>gibb</li>
_HERE_


@data = split "\n",<<'_HERE_';
*hoge
*fuga
*liliugaeo
*gibb
_HERE_

is Text::KuaiWiki::build_ulol(@data), <<'_HERE_';
<ul>
<li>hoge</li>
<li>fuga</li>
<li>liliugaeo</li>
<li>gibb</li>
</ul>
_HERE_


@data = split "\n",<<'_HERE_';
*hoge
*fuga
*kkd
**lige
**ookga
***fukkgae
***dalgae
**hoge
*lge
*hoge
**dkka
**kdga
_HERE_

is Text::KuaiWiki::build_ulol(@data), <<'_HERE_';
<ul>
<li>hoge</li>
<li>fuga</li>
<li>kkd
<ul>
<li>lige</li>
<li>ookga
<ul>
<li>fukkgae</li>
<li>dalgae</li>
</ul>
</li>
<li>hoge</li>
</ul>
</li>
<li>lge</li>
<li>hoge
<ul>
<li>dkka</li>
<li>kdga</li>
</ul>
</li>
</ul>
_HERE_

@data = split "\n",<<'_HERE_';
*hoge
*fuga
*kkd
*#lige
*#ookga
*#*fukkgae
*#*dalgae
*#hoge
*lge
*hoge
**dkka
**kdga
_HERE_

is Text::KuaiWiki::build_ulol(@data), <<'_HERE_';
<ul>
<li>hoge</li>
<li>fuga</li>
<li>kkd
<ol>
<li>lige</li>
<li>ookga
<ul>
<li>fukkgae</li>
<li>dalgae</li>
</ul>
</li>
<li>hoge</li>
</ol>
</li>
<li>lge</li>
<li>hoge
<ul>
<li>dkka</li>
<li>kdga</li>
</ul>
</li>
</ul>
_HERE_

my $str = <<'_HERE_';
this is test of parse wiki.
*one
*two
*three
*four

zen me yang?

#yi
#er
#san
#si

nested.
*hoge
**fua
**piyo
*goooooooo

_HERE_


is Text::KuaiWiki::format_blocks($str), <<'_HERE_';
this is test of parse wiki.

<ul>
<li>one</li>
<li>two</li>
<li>three</li>
<li>four</li>
</ul>


zen me yang?


<ol>
<li>yi</li>
<li>er</li>
<li>san</li>
<li>si</li>
</ol>


nested.

<ul>
<li>hoge
<ul>
<li>fua</li>
<li>piyo</li>
</ul>
</li>
<li>goooooooo</li>
</ul>


_HERE_

@data = split "\n",<<'_HERE_';
:dt
::dd
:dt:dd
:dtdt
:dttt
::dddd
_HERE_

is Text::KuaiWiki::build_dl(@data), <<'_HERE_';
<dl>
<dt>dt</dt>
<dd>dd</dd>
<dt>dt</dt><dd>dd</dd>
<dt>dtdt</dt>
<dt>dttt</dt>
<dd>dddd</dd>
</dl>
_HERE_

@data = split "\n",<<'_HERE_';
>this is quote
>this is quotetete.
>is that quote?
_HERE_

is Text::KuaiWiki::build_blockquote(@data), <<'_HERE_';
<blockquote>
<p>
this is quote<br>
this is quotetete.<br>
is that quote?
</p>
</blockquote>
_HERE_



@data = split "\n",<<"_HERE_";
| !fruits | !vegetables | !seasonings |
| apple   | cabbage     | salt        |
| orange  | carrot      | sugar       |
| banana  | radish      | soy source  |
| pear    | pumpkin     | vinegar     |
_HERE_

is Text::KuaiWiki::build_table(@data), <<'_HERE_';
<table>
<tr>
<th>fruits</th><th>vegetables</th><th>seasonings</th>
</tr>
<tr>
<td>apple</td><td>cabbage</td><td>salt</td>
</tr>
<tr>
<td>orange</td><td>carrot</td><td>sugar</td>
</tr>
<tr>
<td>banana</td><td>radish</td><td>soy source</td>
</tr>
<tr>
<td>pear</td><td>pumpkin</td><td>vinegar</td>
</tr>
</table>
_HERE_

@data = split "\n",<<'_HERE_';
!hoge
!_gaeee
!__gaga
_HERE_


is Text::KuaiWiki::build_headding(@data),<<'_HERE_';

<h2>hoge</h2>

<h3>gaeee</h3>

<h4>gaga</h4>
_HERE_

@data = split "\n",<<'_HERE_';
 this is pre
 this is prere.
 is that pre?
_HERE_

is Text::KuaiWiki::build_pre(@data), <<'_HERE_';
<pre>this is pre
this is prere.
is that pre?</pre>
_HERE_

##########################################################
$str = <<'_HERE_';
!hoge
!_gaeee
!__gaga

this is test of parse wiki.
*one
*two
*three
*four

zen me yang?

#yi
#er
#san
#si

nested.
*hoge
**fua
**piyo
*goooooooo

| !fruits | !vegetables | !seasonings |
| apple   | cabbage     | salt        |
| orange  | carrot      | sugar       |
| banana  | radish      | soy source  |
| pear    | pumpkin     | vinegar     |

:dt
::dd
:dt:dd
:dtdt
:dttt
::dddd

>this is quote
>this is quotetete.
>is that quote?

 this is pre
 this is prere.
 
 is that pre?

_HERE_
is Text::KuaiWiki::format_blocks($str),<<'_HERE_';


<h2>hoge</h2>

<h3>gaeee</h3>

<h4>gaga</h4>


this is test of parse wiki.

<ul>
<li>one</li>
<li>two</li>
<li>three</li>
<li>four</li>
</ul>


zen me yang?


<ol>
<li>yi</li>
<li>er</li>
<li>san</li>
<li>si</li>
</ol>


nested.

<ul>
<li>hoge
<ul>
<li>fua</li>
<li>piyo</li>
</ul>
</li>
<li>goooooooo</li>
</ul>



<table>
<tr>
<th>fruits</th><th>vegetables</th><th>seasonings</th>
</tr>
<tr>
<td>apple</td><td>cabbage</td><td>salt</td>
</tr>
<tr>
<td>orange</td><td>carrot</td><td>sugar</td>
</tr>
<tr>
<td>banana</td><td>radish</td><td>soy source</td>
</tr>
<tr>
<td>pear</td><td>pumpkin</td><td>vinegar</td>
</tr>
</table>



<dl>
<dt>dt</dt>
<dd>dd</dd>
<dt>dt</dt><dd>dd</dd>
<dt>dtdt</dt>
<dt>dttt</dt>
<dd>dddd</dd>
</dl>



<blockquote>
<p>
this is quote<br>
this is quotetete.<br>
is that quote?
</p>
</blockquote>



<pre>this is pre
this is prere.
<!-- dummy -->
is that pre?</pre>


_HERE_

$str = <<'_HERE_';
this is test of '''format_inline'''.
sate ''em'' douderuka?
kou---deruno---+++kamosirenai+++.
_HERE_
is Text::KuaiWiki::format_inlines($str), <<'_HERE_';
this is test of <strong>format_inline</strong>.
sate <em>em</em> douderuka?
kou<del>deruno</del><ins>kamosirenai</ins>.
_HERE_

$str = <<'_HERE_';
 this is pre
 this is prere.///removed
 is that pre? /// to be removed
 hoge.
_HERE_

is Text::KuaiWiki::remove_comment($str), <<'_HERE_';
 this is pre
 this is prere.
 is that pre? 
 hoge.
_HERE_

$str = <<'_HERE_';
this is test of '''format_inline.
sate em douder'''uka''?

kou''---deruno---+++kamosirenai+++.
_HERE_
is Text::KuaiWiki::format_inlines($str), <<'_HERE_';
this is test of <strong>format_inline.
sate em douder</strong>uka''?

kou''<del>deruno</del><ins>kamosirenai</ins>.
_HERE_

$str = <<'_HERE_';
this is [[anchor]] test.
this is [[anchor|http://localhost/~smwiki/]] test;
hoge
_HERE_

is Text::KuaiWiki::set_anchors($str), <<'_HERE_';
this is <a href="anchor">anchor</a> test.
this is <a href="http://localhost/~smwiki/">anchor</a> test;
hoge
_HERE_

$str = <<'_HERE_';
this is  test.

this is  test;
hoge

thisis teete
hogegege
_HERE_

is Text::KuaiWiki::build_p_and_br($str), <<'_HERE_';
<p>
this is  test.
</p>
<p>
this is  test;<br>
hoge
</p>
<p>
thisis teete<br>
hogegege
</p>
_HERE_

$str = <<'_HERE_';
!hoge
!_gaeee
!__gaga

This is last test.

this is test of parse wiki.
*one
*two
*three
*four

zen me yang?

#yi
#er
#san
#si

nested.
*hoge
**fua
**piyo
*goo''ooo''ooo

| !fruits | !vegetables   | !seasonings |
| apple   | ---cabbage--- | +++salt+++  |
| orange  | carrot        | sugar       |
| banana  | radish        | soy source  |
| pear    | pumpkin       | vinegar     |

:dt
::dd
:dt:dd
:dtdt
:dttt
::dddd

>this is quote
>this is '''quotetete'''.
>is that quote?

 this is pre
 this is prere.
 
 is that pre?

>this is test of '''format_inline'''.
>sate ''em'' do[[uderu]]ka?
>kou---deruno---+++kamosirenai+++.


_HERE_

is Text::KuaiWiki::build_wiki($str), <<'_HERE_';
<h2>hoge</h2>
<h3>gaeee</h3>
<h4>gaga</h4>
<p>
This is last test.
</p>
<p>
this is test of parse wiki.
</p>
<ul>
<li>one</li>
<li>two</li>
<li>three</li>
<li>four</li>
</ul>
<p>
zen me yang?
</p>
<ol>
<li>yi</li>
<li>er</li>
<li>san</li>
<li>si</li>
</ol>
<p>
nested.
</p>
<ul>
<li>hoge
<ul>
<li>fua</li>
<li>piyo</li>
</ul>
</li>
<li>goo<em>ooo</em>ooo</li>
</ul>
<table>
<tr>
<th>fruits</th><th>vegetables</th><th>seasonings</th>
</tr>
<tr>
<td>apple</td><td><del>cabbage</del></td><td><ins>salt</ins></td>
</tr>
<tr>
<td>orange</td><td>carrot</td><td>sugar</td>
</tr>
<tr>
<td>banana</td><td>radish</td><td>soy source</td>
</tr>
<tr>
<td>pear</td><td>pumpkin</td><td>vinegar</td>
</tr>
</table>
<dl>
<dt>dt</dt>
<dd>dd</dd>
<dt>dt</dt><dd>dd</dd>
<dt>dtdt</dt>
<dt>dttt</dt>
<dd>dddd</dd>
</dl>
<blockquote>
<p>
this is quote<br>
this is <strong>quotetete</strong>.<br>
is that quote?
</p>
</blockquote>
<pre>this is pre
this is prere.

is that pre?</pre>
<blockquote>
<p>
this is test of <strong>format_inline</strong>.<br>
sate <em>em</em> do<a href="uderu">uderu</a>ka?<br>
kou<del>deruno</del><ins>kamosirenai</ins>.
</p>
</blockquote>
_HERE_



$str = <<'_HERE_';
gaoehga
{{pcode:
#/usr/bin/perl
use strict;
use warnings;
use utf8;
print hoge;
}}
gaehoga
ddda
_HERE_

is Text::KuaiWiki::build_extension_tags($str), <<'_HERE_';
gaoehga

<pre><code><!-- dummy -->#/usr/bin/perl
<!-- dummy -->use strict;
<!-- dummy -->use warnings;
<!-- dummy -->use utf8;
<!-- dummy -->print hoge;</code></pre>

gaehoga
ddda
_HERE_

$str = 'div#main > div.section.cate1';
is Text::KuaiWiki::_make_tag($str), '<div id="main"><div class="section cate1">';



$str = <<'_HERE_';
[[[index]]]

{{div.hoge:
start.
like this {{div.fuga: nest}}

}}

[[hoge

]]

then
_HERE_

is Text::KuaiWiki::build_wiki($str),  <<'_HERE_';
<p>
[<a href="index">index</a>]
</p>
<div class="hoge">
start.
like this 
<div class="fuga">
nest
</div>

</div>

<p>
[[hoge
</p>
<p>
]]
</p>
<p>
then
</p>
_HERE_

@data = split "\n",<<'_HERE_';
!#idd hoge
!_.sec gaeee
!__.sec#hoge gaga
_HERE_


is Text::KuaiWiki::build_headding(@data),<<'_HERE_';

<h2 id="idd">hoge</h2>

<h3 class="sec">gaeee</h3>

<h4 id="hoge" class="sec">gaga</h4>
_HERE_


$str = <<'_HERE_';
this is test.

.cls have class?
ok or not.

{{img.attach : http://www.kuaiwiki.com/etc/img/kuaiwiki.png, KuaiWikiLogo}}

[[{{img : http://www.kuaiwiki.com/etc/img/kuaiwiki.png, Link_to_KuaiWiki}}| http://www.kuaiwiki.com]]
_HERE_

is Text::KuaiWiki::build_wiki($str),  <<'_HERE_';
<p>
this is test.
</p>
<p class="cls">
have class?<br>
ok or not.
</p>
<p>
<img class="attach" src="http://www.kuaiwiki.com/etc/img/kuaiwiki.png" alt="KuaiWikiLogo">
</p>
<p>
<a href="http://www.kuaiwiki.com"><img src="http://www.kuaiwiki.com/etc/img/kuaiwiki.png" alt="Link_to_KuaiWiki"></a>
</p>
_HERE_




