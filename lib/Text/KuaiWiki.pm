package Text::KuaiWiki;
use strict;
use warnings;
use utf8;
our $VERSION = '0.01';


use base qw/Exporter/;
our @EXPORT = qw/build_wiki/;


# This Way allows only one syntax each <tag>. It's problem...
# Is it better to store /regex/ into %MARKS ?
# But it isn't convenient to Users setting personal syntaxes.
our %MARKS = (
    ul              => '*',
    ol              => '#',
    table           => '|',
    th              => '!',
    headding        => '!',
    headding_indent => '_',
    dl              => ':',
    blockquote      => '>', # '>' is target of "HTML filter". It's problem. 
    pre             => ' ',
    component          => '%',
);
our $MAX_LI_DEPTH = 0; # 0 as no limit

#each values of %INLINE_MARKS must be UNIQ!
our %INLINE_MARKS = (
    em         => q{''}, #q{'} is target of "HTML filter".
    strong     => q{'''},
    del        => q{---},
    ins        => q{+++},
);

our $COMMENT_MARK = '///'; # zantei
our $HR_MARK      = '===';

our %ANCHOR_MARKS = (
    start     => '[[',
    end       => ']]',
    separator => '|',
);

our $HEADDING_START_FROM = 2; #h2

my @INLINE_TAGS = qw/a cite code span img kbd samp abbr dfn q/;

#implemented            /ol ul table h2 h3 h4 dl blockquote pre strong em ins del hr a/
#format_blocks          /ol ul table h2 h3 h4 dl blockquote pre pre>code/
#haven't implemented    /code img pre>code/
#pendding               /footnote /
#implements?            /floated block, iframe, amazon(w), [[toc]] component % toc
#extension              /{{ hoge }}

# 0. add "\n" to last
# 1. remove_comment
# 2. filter '&','<','>','"',
# 3. build_extension_tags, set_anchor, build_hr, 
# 4. ^&gt; -> '>'
# 5. format_blocks
# 6. format_inlines
# 7. filter "'"
# 8. <p> and <br>
sub build_wiki{
    my $text = shift;
    
    $text = "\n\n$text\n";
    $text = remove_comment($text);
    
    $text =~ s/&(?![#a-zA-Z0-9]{1,8};)/&amp;/g; #don't translate Like 'Character reference'. ex &amp;
    $text =~ s/</&lt;/g;
    $text =~ s/>/&gt;/g;
    $text =~ s/\"/&quot;/g;
    
    #line head back slash escape
    $text =~ s/^\\/<!-- dummy -->/gms;
    
    $text = build_extension_tags($text);
    
    $text = set_anchors($text);
    $text = build_hr($text);
    
    $text = set_imgs($text);
    
    $text =~ s/^&gt;/>/gms;
    $text = format_blocks($text);
    $text = format_inlines($text);
    
    $text =~ s/'/&#39;/g;
    
    ( $text, my $footnote ) = make_footnote($text);
    
    $text = build_p_and_br($text);
    $text =~ s/<!-- dummy -->//g;
    
    $text = _fix_html($text);
    
    $text .= $footnote if $footnote;
    
    return $text;
}

my %fn_mark = (
    start => '((',
    end   => '))',
);

sub make_footnote{
    my $text = shift;
    my $fn_cnt = 1;
    
    my $fn_st_reg  = quotemeta $fn_mark{'start'};
    my $fn_end_reg = quotemeta $fn_mark{'end'};
    
    my @footnotes;
    
    while( my ($fn) = $text =~ /($fn_st_reg.*?$fn_end_reg)/gm ){
        my $org = quotemeta $fn;
        $fn =~ s/$fn_st_reg//; $fn =~ s/$fn_end_reg//;
        my $fn_anchor = '<a class="footnote" '.
                        'id="fna' . $fn_cnt . '" href="#fn' . $fn_cnt .'">' .
                        "[$fn_cnt]" .
                        '</a>';
        $text =~ s/$org/$fn_anchor/;
        push @footnotes, '<li id="'. "fn$fn_cnt" .'">'.
                         '<a href="' . "#fna$fn_cnt" . '">' . "*$fn_cnt" . '</a>'.
                         $fn .
                         "</li>\n";
        $fn_cnt++;
    }
    
    my $footnote;
    $footnote = '<ul id="footnote">' . "\n" . join("\n", @footnotes) . "</ul>\n" if @footnotes;
    
    return ( $text, $footnote );
}

sub set_imgs{
    my $text = shift;
    while( my ($img_info) = $text =~ /(%img\(.*?\))/ ){
        my $orgin = quotemeta $img_info;
        $img_info =~ s/^%img\(//; $img_info =~ s/\)$//;
        my $img_attr = _make_img_attr($img_info);
        
        my $img_tag = '';
        $img_tag = "<img$img_attr>";
        
        $text =~ s/$orgin/$img_tag/;
    }
    return $text;
}


sub set_anchors{
    my $text = shift;
    my $a_start_reg    = quotemeta $ANCHOR_MARKS{'start'};
    my $a_end_reg      = quotemeta $ANCHOR_MARKS{'end'};
    my $a_seperate_reg = quotemeta $ANCHOR_MARKS{'separator'};
    while( my ($anchor) = $text =~ /($a_start_reg(?:[^\[\]](?!\n\n))*?$a_end_reg)/sm ){
        my $origin = quotemeta $anchor;
        $anchor =~ s/^$a_start_reg//; $anchor =~ s/$a_end_reg$//;
        my ($title, $url) = split /\s*$a_seperate_reg\s*/,$anchor,2;
        $url = $title unless $url;
        
        if($url !~ /\//){
            if( $url =~ s/^#// ){
                $url = '#'. _url_encode($url);
            }
            else{
                $url = _url_encode($url);
            }
        }
        $anchor = qq{<a href="$url">$title</a>};
        $text =~ s/$origin/$anchor/;
    }
    return $text;
}

sub format_inlines{
    my $text = shift;
    # make hash of {mark => tag_name}
    my %tag_dic = reverse %INLINE_MARKS;
    
    #longer mark has priority
    my @marks = map  { quotemeta $_->[0] }
                sort { $b->[1] <=> $a->[1] }
                map  { [$_, length($_)] }
                keys %tag_dic;
    local $" = '|'; # array seperation charachter for regex
    #can tag multi line. but don't tag over blank line. ex. fug'''hoge \n\n geho'''gg
    while( my ($inline, $mark) = $text =~ /((@marks)(?:.(?!\n\n))*?\2)/ms){
        my $origin = quotemeta $inline;
        my $tag = $tag_dic{$mark};
        $mark = quotemeta $mark;
        $inline =~ s/^$mark//; $inline =~ s/$mark$//;
        $inline = "<$tag>$inline</$tag>";
        $text =~ s/$origin/$inline/;
    }
    return $text;
}

my %build_subs = (
    $MARKS{'ul'}          => \&build_ulol,
    $MARKS{'ol'}          => \&build_ulol,
    $MARKS{'table'}       => \&build_table,
    $MARKS{'headding'}    => \&build_headding,
    $MARKS{'dl'}          => \&build_dl,
    $MARKS{'blockquote'}  => \&build_blockquote,
    $MARKS{'pre'}         => \&build_pre,
);

sub format_blocks{
    my $text = shift;
    local $" = '|'; # array seperation charachter for regex
    my @marks = map{quotemeta} keys %build_subs;
    while(my ($block, $mark) = $text =~ /((?:^(@marks).*?\n)(?:^\2.*?\n)*)/m){
        my $origin = quotemeta $block;
        $block = $build_subs{$mark}->(split "\n",$block);
        $text =~ s/$origin/\n$block\n/;
    }
    return $text;
}

#should implement max recursion depth.
sub build_ulol{
    my @li = @_;
    my @ulol_reg = ( quotemeta($MARKS{'ul'}), quotemeta($MARKS{'ol'}) );
    local $" = '|';
    if($MAX_LI_DEPTH){
        s/^((?:@ulol_reg){$MAX_LI_DEPTH})(@ulol_reg)/$1<!-- c -->$2/ for @li;
    }
    
    my ($list_mark) = $li[0] =~ /^(@ulol_reg)/;
    s/^(?:@ulol_reg)\s?// for @li;
    unless(map {/^(?:@ulol_reg)/} @li){
        my $tag = $list_mark eq $MARKS{'ul'} ? 'ul' :
                  $list_mark eq $MARKS{'ol'} ? 'ol' : '';
        my $result = "<$tag>\n" . build_li(@li) . "</$tag>\n";
        $result =~ s/<!-- c -->// if $MAX_LI_DEPTH;
        return $result;
    }
    
    my @nest_li;
    my $start_idx;
    for (0..$#li){
        if($li[$_] =~ /^(?:@ulol_reg)/){
            push @nest_li, $li[$_] ;
            $start_idx = $_ unless defined($start_idx);
        }
        elsif(@nest_li){last;}
    }
    if($start_idx != 0){
        $li[$start_idx-1] .= "\n".build_ulol(@nest_li);
    }
    else{
        $li[0] = "\n". build_ulol(@nest_li);
    }
    splice(@li, $start_idx+1, $#nest_li);
    splice(@li, $start_idx, 1) if $start_idx != 0;
    
    s/^/$list_mark/ for @li;
    return build_ulol(@li);
}

#return <li> elements
sub build_li{
    my $str = join "</li>\n<li>", @_;
    return "<li>$str</li>\n";
}

#can't nest. 
#don't implement rowspan, colspan, caption, thead, tbody.
sub build_table{
    my $table_reg = quotemeta $MARKS{'table'};
    my $th_reg = quotemeta $MARKS{'th'};
    my @rows = @_;
    my $table = "<table>\n";
    for(@rows){
        s/^$table_reg//;
        #if '|' is escaped (like '\|'), should ignore.
        #haven't implement
        my @cells = split /$table_reg/, $_;
        for(@cells){
            s/^\s+//; s/\s+$//;
            my $tag = 'td';
            $tag = 'th' if s/^$th_reg//;
            $_ = "<$tag>$_</$tag>";
        }
        $table .= "<tr>\n". join("",@cells) . "\n</tr>\n";
    }
    $table .= "</table>\n";
    return $table;
}

sub build_headding{
    my @h = @_;
    my $headding_reg       = quotemeta $MARKS{'headding'};
    my $headding_indent_reg = quotemeta $MARKS{'headding_indent'};
    
    my $str = '';
    for(@h){
        s/^(?:$headding_reg)//;
        my ($headding_num) = $_ =~ /^($headding_indent_reg*)/;
        $headding_num = length($headding_num ) / length($MARKS{'headding_indent'}) + $HEADDING_START_FROM;
        $headding_num = 6 if $headding_num > 6; # h6 is max
        my $tag = 'h'.$headding_num;
        
        my $delete_max = 6 - $HEADDING_START_FROM;
        s/^(?:$headding_indent_reg){0,$delete_max}//;
        
        my $start_tag = "<$tag>";
        if( my ($class_id) = $_ =~ /^((?:(?:\.|#)(?:[a-zA-Z][-0-9a-zA-Z]*))+)\s/ )
        {
            s/^\Q$class_id\E//;
            $start_tag = _make_tag("$tag$class_id");
        }
        s/^\s//;
        $str .= "\n$start_tag$_</$tag>\n";
    }
    return $str;
}

sub build_dl{
    my @dl = @_;
    my $dl_reg = quotemeta $MARKS{'dl'};
    my $dl = "<dl>\n";
    for(@dl){
        s/^$dl_reg\s?//;
        my @dtdd = split /$dl_reg\s?/,$_,2;
        $dl .= "<dt>$dtdd[0]</dt>" if $dtdd[0] ne '';
        $dl .= "<dd>$dtdd[1]</dd>" if defined($dtdd[1]) && ($dtdd[1] ne '');
        $dl .= "\n";
    }
    return "$dl</dl>\n";
}

sub build_blockquote{
    my @blockquote = @_;
    my $blockquote_reg = quotemeta $MARKS{'blockquote'};
    s/^$blockquote_reg\s?// for @blockquote;
    my $blockquote = join "\n",@blockquote;
    $blockquote = build_p_and_br($blockquote);
    return "<blockquote>\n$blockquote</blockquote>\n";
}

#preの中は入れ子に出来ない、Block記法は追加で適用されない。
sub build_pre{
    my @pre = @_;
    my $pre_reg = quotemeta $MARKS{'pre'};
    
    local $" = '|'; # array seperation charachter for regex
    my @marks = map{quotemeta} keys %build_subs;
    
    for(@pre){
        s/^$pre_reg//;
        s/^(@marks)/<!-- dummy -->$1/; #not a smart solution!
        s/^$/<!-- dummy -->/;
    }
    return "<pre>" . join("\n",@pre) . "</pre>\n";
}

# transfer HTML comment or remove? removing at present.
sub remove_comment{
    my $text = shift;
    my $comment_reg = quotemeta $COMMENT_MARK;
    $text =~ s!$comment_reg.*?$!!gm;
    return $text;
}

# if using xhtml, should use <hr />. How is it?
sub build_hr{
    my $text = shift;
    my $hr_reg = quotemeta $HR_MARK;
    $text =~ s/^$hr_reg$/\n<hr>\n/msg;
    return $text;
}


sub _args_check{
    my $args = shift;
    return unless $args =~ s/\)$//;
    return if $args =~ /\$/;
    return if $args =~ /@\{/;
    
    my @args = split /\s*,\s*/, $args;
    for(@args){
        if( /^(['"]).*\1$/ )
        {
            my $quot = substr($_, 0, 1);
            s/^['"]//; s/["']$//;
            my $escaping = 0;
            for my $i ( 0..length($_) - 1 ){
                my $char = substr($_, $i, 1);
                return if ($char =~ /['"]/) && !$escaping;
                
                if( $escaping ){
                    $escaping = 0;
                }
                elsif( $char eq '\\' )
                {
                    $escaping = 1;
                }
            }
            $_ = eval($quot.$_.$quot);
        }
        elsif( m|[^-.+0-9*/]| ){
            return;
        }
    }
    return @args;
}

sub build_p_and_br{
    my @blocks = split /\n{2,}/m, shift;
    shift @blocks if $blocks[0] =~ /^(\s|\n)*$/ms;
    
    my $save_idx = undef;
    my @tag_stack;
    my $i = -1;
    for(@blocks){
        $i++;
        s/\A\n+//ms; s/\n+\z//ms;
        my ($start_tag) = $_ =~ m{\A\s*<([^-!\s>/]+)}m; #add '-!'
        my ($end_tag) = $_ =~ m{</([^\s>/]+)>[\s\n]*\z}m;
        
        if($start_tag){
            #tag is inline elm
            if( grep { $start_tag eq $_ } ((keys %INLINE_MARKS),@INLINE_TAGS)){
                if( @tag_stack && 
                    $end_tag              && 
                    ( $end_tag eq $tag_stack[$#tag_stack] ))
                    {
                    pop @tag_stack;
                }
            }
            else{ #tag is block elm
                next if $start_tag eq 'hr';
                
                if( $end_tag && ( $start_tag eq $end_tag ) ){
                    next unless @tag_stack;
                }
                else{ # block tag is not close
                    $save_idx = $i unless @tag_stack;
                    push @tag_stack, $start_tag;
                }
            }
        }
        elsif($end_tag){
            if( @tag_stack && 
                ($end_tag eq $tag_stack[$#tag_stack]) )
                {
                pop @tag_stack;
            }
        }
        
        if( defined $save_idx ){
            if( $i != $save_idx ){ #join with prev block.
                $blocks[$save_idx] .= "\n$_";
                $_ = '';
            }
            $save_idx = undef unless @tag_stack;
            next;
        }
        
        next if s/^\s*$//;
        
        my $tag = "<p>";
        if( my ($class) = $_ =~ /^((?:\.(?:[a-zA-Z][-0-9a-zA-Z]*))+)\s/ )
        {
            s/^\Q$class\E\s//;
            $tag = _make_tag("p$class");
        }
        s/\n/<br>\n/msg;
        s{\A}{$tag\n}ms; s{\z}{\n</p>}ms;
    }
    return join("\n",@blocks)."\n";
}

our %EXTENSION_MARKS = (
    start => '{{',
    end   => '}}',
);

our %EXTENSION_TAGS = (
    pcode  => '<pre><code>',
);

sub build_extension_tags{
    my $text = shift;
    my $ex_start = quotemeta $EXTENSION_MARKS{'start'};
    my $ex_end   = quotemeta $EXTENSION_MARKS{'end'};
    while ( my ($extension, $tag, $content) = $text =~ /($ex_start(.*?)\s*:\s*(.*?)$ex_end)/ms ){

        my $pre_flag = ($tag =~ /^(?:pre|pcode)\b/) ? 1 : 0;
        my $inside_flag = 0;
        while( $content =~ /$ex_start.*?:/ ){
            $inside_flag = 1;
            ($extension, $tag, $content) = 
                "$content$EXTENSION_MARKS{'end'}" =~ /($ex_start(.*?)\s*:\s*(.*?)$ex_end)/ms;
        }
        my $tag_name = $tag;
        $tag_name =~ s/[.#].*$//; # delete class, id information
        
        my $orgin = $extension;
        $extension = quotemeta $extension;
        
        if( $pre_flag && $inside_flag ){
            $orgin =~ s/([-+'{}=\[\]\(\)])/'&#'.ord($1).';'/eg;
            $text =~ s/$extension/$orgin/ms;
            next;
        }
        
        $tag = $EXTENSION_TAGS{$tag} ? $EXTENSION_TAGS{$tag} : _make_tag($tag);
        my $end_tag = _make_end_tag($tag);
        
        $content =~ s/\A\n//; $content =~ s/\n\z//;
        $content =~ s/([-+'{}=\[\]\(\)])/'&#'.ord($1).';'/eg if ($tag_name eq 'pcode') || ($tag_name eq 'pre');
        
        my $newline_inner_tag = '';
        #ブロック要素の場合は、開きタグ前後、閉じタグ前後に改行をはさまないといけない。
        #(ただし、pre, codeは開きタグ直後、閉じタグ直前には改行を入れない)
        $newline_inner_tag = "\n" unless grep { $tag_name eq $_ } ((keys %INLINE_MARKS),@INLINE_TAGS);
        my $newline_outer_tag = $newline_inner_tag;
        $newline_inner_tag = '' if ($tag_name eq 'pcode') || ($tag_name eq 'pre');
        
        if( ($tag_name ne 'pre') && ($tag_name ne 'pcode') ){
            $content =~ s{^$}{<!-- dummy -->}gms; #空白行を埋める
        }
        else{ #preは入れ子禁止
            $content =~ s{^}{<!-- dummy -->}gms;
        }
        
        if( $tag_name ne 'img' ){
            $content = $newline_outer_tag.$tag.$newline_inner_tag.$content.$newline_inner_tag.$end_tag.$newline_outer_tag;
        }
        else{
            $content = _make_img_attr($content);
            $tag =~ s/>$//;
            $content = $tag.$content.'>' if $content;
        }
        
        $text =~ s/$extension/$content/ms;
    }
    return $text;
}

our @ALLOW_TAGS = qw/div address span cite pre code h2 h3 h4 h5 h6 p img ins del abbr dfn q kbd samp blockquote/;

sub _make_img_attr{
    my $content = shift;
    $content =~ s/\s//g;
    my ($img_uri, $alt) = split /,/, $content, 2;
    #return '' unless $img_uri =~ m!^https?://.*/.*\.(jpe?g|gif|png)$!;
    return '' unless $img_uri =~ m!\.(jpe?g|gif|png)$!;
    $alt = '' unless $alt;
    
    return qq{ src="$img_uri" alt="$alt"};
}

sub _make_tag{
    my $tag = shift;
    $tag =~ s{&gt;}{>}g;
    
    my @tags = split /\s?>\s?/,$tag;
    for(@tags){
        s/\s//g;
        my ($tag_name, $option) = $_ =~ /^([^.#\[]+)(.*)$/;
        $_ = $tag_name . _make_id_and_class($option);

        if(grep { $tag_name eq $_ } @ALLOW_TAGS){
            $_ = '<'.$_.'>';
        }
        else{
            $_ = '';
        }
    }
    return join "", @tags;
}

sub _make_id_and_class{
    my $str = shift;
    
    my ($op_attr) = $str =~ /\[(.*)\]/;
    $str =~ s/\[(.*)\]// if $op_attr;
    
    return '' if (!$str && !$op_attr) || ($str =~ /[^-.0-9a-zA-Z#]/);
    
    my (@ids, @classes); local $1;
    while( $str =~ /((?:\.|#)(?:[a-zA-Z][-0-9a-zA-Z]*))/g ){
        my $attr = $1;
        if ( substr( $attr, 0, 1 ) eq '#' ){ push @ids,     substr($attr, 1); }
        else                               { push @classes, substr($attr, 1); }
    }
    
    my $ret = '';
    $ret .= ' id="' . join(' ',@ids) . '"' if @ids;
    $ret .= ' class="' . join(' ',@classes) . '"' if @classes;
    $ret .= _make_attr($op_attr) if $op_attr;
    
    return $ret;
}

sub _make_attr{
    my $attr_str = shift;
    my @attrs = split /,/, $attr_str;
    my $ret = '';
    for(@attrs){
        my ($attribute, $value) = split /=/, $_;
        next unless $attribute && $value;
        next if $attribute =~ /^on/i;
        next if lc $attribute eq 'style';
        $ret .= qq{ $attribute="$value"};
    }
    return $ret;
}


sub _make_end_tag{
    my $end_tag = shift; 
    $end_tag =~ s{<}{</}g; $end_tag =~ s{\s[^>]*>}{>}g;
    
    my @end_tags = split /></,$end_tag;
    @end_tags = reverse @end_tags;
    for(@end_tags){
        $_ = '<'.$_ if /^[^<]/; $_ .= '>' if /[^>]$/;
    }
    $end_tag = join '', @end_tags;
    return $end_tag;
}

sub _fix_html{
    my $html = shift;
    $html =~ s!^<p>\n(</[a-z1-6]+>)\n</p>!$1!msg;
    return $html;
}

sub _url_encode {
    my $str = shift;
    utf8::encode($str) if Encode::is_utf8($str);
    $str =~ s/([^\w ])/'%'.unpack('H2', $1)/eg;
    $str =~ tr/ /+/;
    return $str;
}


1;

