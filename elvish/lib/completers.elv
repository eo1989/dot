use re
use str
use util

use github.com/xiaq/edit.elv/compl/git
git:apply

fn overlap-at [a b]{
  for i [(range 1 (- (count $b) 1))] {
    if (has-value $a $b[$i]) { put $i; return }
  }
  put $false
}

fn prefix-completer [p a]{
  edit:completion:arg-completer[$p] = [@cmd]{
    if (eq (count $cmd) 2) {
      $a $@cmd
    } elif (has-key $edit:completion:arg-completer $cmd[1]) {
      $edit:completion:arg-completer[$cmd[1]] (all $cmd[1:])
    } else {
      edit:complete-filename $cmd[-1]
    }
  }
}

fn complete-directory [a]{
  dir = (path-dir $a)/
  if (has-prefix $a $dir) {
    a = (str:replace &max=1 $dir '' $a)
  } else {
    dir = ''
  }
  for x [$dir*[match-hidden][nomatch-ok]$a*[match-hidden][nomatch-ok]] {
    if (-is-dir $x) { edit:complex-candidate &code-suffix=/ &style='blue;bold' $x }
  }
}

edit:completion:arg-completer[cd] = [@cmd]{
  if (eq (count $cmd) 2) {
    complete-directory $cmd[1]
  }
}

edit:completion:arg-completer[kak] = [@cmd]{
  if (eq $cmd[-2] -c) {
    kak -l
  } else {
    edit:complete-filename $cmd[-1]
  }
}

edit:completion:arg-completer[waifu2x-converter-cpp] = [@cmd]{
  if (has-value [-i --input -o --output] $cmd[-2]) {
    edit:complete-filename $cmd[-1]
  } elif (has-value [-m --mode] $cmd[-2]) {
    put noise scale noise-scale
  } elif (eq $cmd[-2] --noise-level) {
    put 0 1 2 3
  } else {
    put --scale-ratio --noise-level --mode --jobs --png-compression \
      --image-quality --silent -i -o
  }
}

kitty-cmds = $nil
kitty-kittens = $nil

edit:completion:arg-completer[kitty] = [@cmd]{
  if (not $kitty-cmds) {
    @kitty-cmds = (kitty @ --help | peach [x]{ if (re:match '^  \w' $x) { put $x[2:] } })
    @kitty-kittens = (pwd=/usr/lib/kitty/kittens fd main.py | peach [x]{ path-dir $x })
  }
  if (has-value [kitten '+kitten'] $cmd[-2]) {
    all $kitty-kittens
  } elif (eq $cmd[-2] '@') {
    all $kitty-cmds
  } else {
    edit:complete-filename $cmd[-1]
  }
}

edit:completion:arg-completer[sv] = [@cmd]{
  if (eq (count $cmd) 2) {
    put status up down once pause cont hup alarm interrupt quit kill term 1 2 \
      exit start try-restart check {force-,}{stop,reload,restart,shutdown}
  } else {
    pwd=/var/service put *
  }
}

edit:completion:arg-completer[man] = [@cmd]{
  pwd=/bedrock/cross/man put man*/* | each [a]{
    re:replace &literal=$true '(\.\dp?)?(\.gz)?$' '' (path-base $a)
  }
}

edit:completion:arg-completer[kill] = [@cmd]{
  ps -u (whoami) --no-headers -o pid,command |\
    eawk [_ p @c]{ edit:complex-candidate &display=(print ' '$@c) $p }
}

edit:completion:arg-completer[nimble] = [@cmd]{
  if (eq (count $cmd) 2) {
    put {un,}install develop check init publish build c cc js test doc{,2} \
      refresh search list tasks path dump
    if ?(isnimbleproject) {
      nimble tasks 2>&- | eawk [_ a @_]{ put $a }
    }
  } elif (eq $cmd[-2] install) {
    for x (from-json <~/.nimble/packages_official.json) { put $x[name] }
  } elif (eq $cmd[-2] uninstall) {
    idx = (util:index-of $cmd[-1] '@')
    if (== $idx -1) {
      nimble list -i | eawk [_ n @_]{ put $n }
    } else {
      pkgs = [&]
      nimble list -i | eawk [_ n @v]{
        @ver = $@v[:-1]
        ver[0] = $ver[0][1:]
        pkgs[$n] = $ver
      }
      pkg = $cmd[-1][:$idx]
      if (has-key $pkgs $pkg) {
        for v $pkgs[$pkg] { put $pkg@$v }
      }
    }
  }
}

pijul-cmds = [add apply branches checkout clone credit delete-branch diff dist\
            generate-completions help init key log ls mv patch pull push\
            record remove revert rollback show-dependencies sign status tag unrecord]

edit:completion:arg-completer[pijul] = [@cmd]{
  if (eq (count $cmd) 2) {
    all $pijul-cmds
  }
}

neofetch-img = [ascii caca iterm2 jp2a kitty pixterm sixel termpix tycat w3m off]
neofetch-opts = $nil

edit:completion:arg-completer[neofetch] = [@cmd]{
  if (not $neofetch-opts) {
    neofetch-opts = [(_ = ?(neofetch --help | each [x]{
      if (has-prefix $x '    --') {
        put $x | eawk [_ a @_]{ put $a }
      }
    })) --logo -L -v -vv]
  }
  all $neofetch-opts
}

edit:completion:arg-completer[bspc] = [@cmd]{
  if (eq (count $cmd) 2) {
    put node desktop monitor query wm rule config subscribe quit
  } elif (eq $cmd[1] subscribe) {
    put all report monitor desktop node pointer
  } elif (eq $cmd[1] rule) {
    put --add --remove --list
  } elif (eq $cmd[1] wm) {
    put --dump-state --load-state --add-monitor --adopt-orphans --record-history --get-status
  } elif (eq $cmd[1] query) {
    put --nodes --desktops --monitors --tree
  }
}

edit:completion:arg-completer[ntr] = [@cmd]{
  if (not (has-prefix $cmd[-1] '-')) {
    pwd=$E:XDG_CONFIG_HOME/ntr/contexts put **
  }
}

edit:completion:arg-completer[mpv] = [@cmd]{
  if (and (> (count $cmd[-1]) 0) (eq $cmd[-1][0] '-')) {
    mpv --list-options | drop 2 | take 872 | eawk [_ a @b]{
      if (eq (count $b) 0) {
        put $a
      } else {
        edit:complex-candidate $a &display=' '(str:join ' ' $b)
      }
    }
  } else {
    edit:complete-filename $cmd[-1]
  }
}

edit:completion:arg-completer[update] = [@cmd]{
  update | each [x]{ if (has-prefix $x "    ") { put $x[4:] } }
}

edit:completion:arg-completer[xr] = [@cmd]{
  xpkg -m
  xpkg -O | peach [x]{ edit:complex-candidate &style='red;inverse' $x }
}

edit:completion:arg-completer[xi] = [@cmd]{
  pwd=$E:XBPS_DISTDIR/srcpkgs put *
}

xbps-src-cmds = $nil
xbps-src-arch = $nil

edit:completion:arg-completer[xbps-src] = [@cmd]{
  if (not $xbps-src-cmds) {
    @xbps-src-cmds = (xbps-src -h | take 129 | drop 4 | each [x]{ put (re:find &max=1 '^\w+(\-\w+)*' $x)[text] })
    @xbps-src-arch = (xbps-src -h | take 162 | drop 136)[1:]
  }
  if (eq $cmd[-2] '-a') {
    all $xbps-src-arch
  } else {
    if (not (overlap-at $xbps-src-cmds $cmd)) {
      all $xbps-src-cmds
    } else {
      pwd=$E:XBPS_DISTDIR/srcpkgs put *
    }
  }
}

edit:completion:arg-completer[strat] = [@cmd]{
  @strata = (brl list)
  has-strat = (overlap-at $strata $cmd)
  if (not $has-strat) {
    all $strata
  } else {
    edit:complete-sudo (all $cmd[(put $has-strat):])
  }
}

brl-cmds = $nil

edit:completion:arg-completer[brl] = [@cmd]{
  if (not $brl-cmds) {
    @brl-cmds = (brl -h | take 36 | drop 5 | each [x]{ put (re:find &max=1 '^  \w+' $x)[text][2:] })
  }
  len = (count $cmd)
  if (== $len 2) {
    all $brl-cmds
  } else {
    c = $cmd[1]
    if (has-value [status enable disable hide show] $c) {
      brl list
    } elif (eq $c fetch) {
      brl fetch -L
    }
  }
}

edit:completion:arg-completer[tam] = [@cmd]{
  if (== (count $cmd) 2) {
    put install uninstall enable disable update list query search
  } else {
    c = $cmd[1]
    if (has-value [uninstall update query] $c) {
      tam list -s
    } elif (eq $c enable) {
      tam list -s -d
    } elif (eq $c disable) {
      tam list -s -e
    } elif (eq $c list) {
      put '--short' '--enabled' '--disabled'
    }
  }
}

edit:completion:arg-completer[promotescript] = [@cmd]{
  pwd=~/.local/bin fd -t f
}

edit:completion:arg-completer[edit-script] = $edit:complete-sudo~
edit:completion:arg-completer[whereis] = $edit:complete-sudo~
edit:completion:arg-completer[which] = $edit:complete-sudo~

edit:completion:arg-completer[xq] = $edit:completion:arg-completer[xi]
edit:completion:arg-completer[xqt] = $edit:completion:arg-completer[xi]
edit:completion:arg-completer[xbps-install] = $edit:completion:arg-completer[xi]

prefixes = [
  &sudo=$edit:complete-sudo~
  &strace=$edit:complete-sudo~
  &time=$edit:complete-sudo~
  &torify=$edit:complete-sudo~
]

for k [(keys $prefixes)] { prefix-completer $k $prefixes[$k] }
