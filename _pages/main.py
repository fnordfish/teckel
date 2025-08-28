import re

BYEXMAPLE_PROMT_RE=re.compile(r"^(>>|\.\.|=>)( |$)", re.M)

def byexample_repl(matchobj):
    if matchobj.group(1) == '=>': return '#=> '
    else: return ''

def define_env(env):
    """
    This is the hook for defining variables, macros and filters

    - variables: the dictionary that contains the environment variables
    - macro: a decorator function, to declare a macro.
    """

    @env.filter
    def remove_code_promt(text):
    	return BYEXMAPLE_PROMT_RE.sub(byexample_repl, text)
