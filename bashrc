# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
        . /etc/bashrc
fi

# User specific aliases and functions
export PS1='[\u@\H:$( pwd )]\$ '
export SPLUNK_HOME=/opt/splunk
export PATH=$SPLUNK_HOME/bin:$PATH

if [ -f  $SPLUNK_HOME/share/splunk/cli-command-completion.sh ]; then
        . $SPLUNK_HOME/share/splunk/cli-command-completion.sh
fi
