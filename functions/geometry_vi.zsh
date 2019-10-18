# geometry_vi - A geometry plugin to display the ZLE vi-mode state.

geometry_vi() {
    # Required for RPROMPT to render properly after submitting a command.
    geometry::vi-get-mode
}

# Re-render the prompt.
function geometry::vi-update-prompt() {
    imode=$(geometry::vi-insert-mode)
    nmode=$(geometry::vi-normal-mode)
    if [[ $KEYMAP == vicmd ]]; then
	PROMPT=${PROMPT//$imode/$nmode}
	RPROMPT=${RPROMPT//$imode/$nmode}
    else
	PROMPT=${PROMPT//$nmode/$imode}
	RPROMPT=${RPROMPT//$nmode/$imode}
    fi
}

# Render normal mode.
function geometry::vi-normal-mode() {
    ansi ${GEOMETRY_VI_NORMAL_COLOR:-white} ${GEOMETRY_VI_NORMAL_MODE:-"<NORMAL>"}
}

# Render insert mode.
function geometry::vi-insert-mode() {
    ansi ${GEOMETRY_VI_INSERT_COLOR:-yellow} ${GEOMETRY_VI_INSERT_MODE:-"<INSERT>"}
}

# Return the currently active mode.
function geometry::vi-get-mode() {
    imode=$(geometry::vi-insert-mode)
    nmode=$(geometry::vi-normal-mode)
    [[ $KEYMAP == vicmd ]] && echo $nmode || echo $imode
}

# ZLE widget to trigger prompt updates.
function geometry::vi-draw-mode {
    keymap=$(geometry::vi-get-mode)
    geometry::vi-update-prompt
    zle reset-prompt
}


# Initialization: Bind the widgets required to perform proper prompt updates.
# Adapted from https://github.com/zsh-users/zsh-syntax-highlighting/blob/master/zsh-syntax-highlighting.zsh#L295-L359
local prefix="geometry_vi"
for w (zle-keymap-select zle-line-pre-redraw zle-line-init zle-line-finish); do
    case ${widgets[$w]:-""} in
	# Already Bound to geometry: Do nothing.
	user:geometry-vi-draw) ;;

	# Existing user widget: Chain a call to it.
	user:*) zle -N $prefix-$w ${widgets[$w]#*:}
		# Dynamically create a function to call the previous widget.
		eval "geometry::${(q)prefix}-${(q)w}() { geometry::vi-draw-mode; builtin zle ${(q)prefix}-${(q)w} -- \"\$@\" }"
		zle -N $w geometry::$prefix-$w;;

	# Completion widgets: Ignore.
	completion:*) ;;

	# Builtin widget: Chain a call to ".widget".
	# Eval is required to get a closure (
	builtin) eval "geometry::${(q)prefix}-${(q)w}() { geometry::vi-draw-mode; builtin zle .${(q)w} -- \"\$@\" }"
		 zle -N $cur_widget _zsh_highlight_widget_$prefix-$cur_widget;;

	# Unbound widget: Bind directly.
	*) 
	    if [[ $w == zle-* ]] && (( ! ${+widgets[$w]} )); then
		zle -N $w geometry::vi-draw-mode
	    else
		# Default: unhandled case.
		print -r -- >&2 "geometry::geometry_vi: unhandled ZLE widget ${(qq)w}"
	    fi
    esac
done