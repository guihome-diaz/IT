#!/bin/bash
#
# To adjust VIM configuration
#
RED="\\033[0;31m"
RED_BOLD="\\033[1;31m"
BLUE="\\033[1;34m"
GREEN="\\033[0;32m"
WHITE="\\033[0;37m"
YELLOW="\\033[1;33m"


function setupVim() {
	ASSETS_PATH="./../assets"
	if [ $# -eq 1 ]; then
	    ASSETS_PATH="$1/assets"
	fi

	export DEBIAN_FRONTEND=dialog

	echo -e "$BLUE "
	echo -e "####################################"
	echo -e "     Updating VIM configuration" 
	echo -e "#################################### $WHITE"
	echo -e " " 

	# VIM colors
	sed -i 's/"set background=dark/set background=dark/g' /etc/vim/vimrc

	# VIM plugins
	sed -i 's/"if has("autocmd")/if has("autocmd")/g' /etc/vim/vimrc
	sed -i 's/"endif/endif/g' /etc/vim/vimrc
	sed -i 's/"  au BufReadPost/  au BufReadPost/g' /etc/vim/vimrc
	sed -i 's/"  au BufReadPost/  au BufReadPost/g' /etc/vim/vimrc
	sed -i 's/"  filetype plugin/  filetype plugin/g' /etc/vim/vimrc

	# VIM options
	sed -i 's/"set showcmd/set showcmd /g' /etc/vim/vimrc
	sed -i 's/"set showmatch/set showmatch /g' /etc/vim/vimrc
	sed -i 's/"set ignorecase/set ignorecase /g' /etc/vim/vimrc
	sed -i 's/"set incsearch/set incsearch /g' /etc/vim/vimrc
	sed -i 's/"set autowrite/set autowrite /g' /etc/vim/vimrc
	sed -i 's/"set hidden/set hidden /g' /etc/vim/vimrc
	echo -e " " >> /etc/vim/vimrc
	echo -e 'set nu                  "Enable line numbers' >> /etc/vim/vimrc
	echo -e 'set ruler               "Enable ruler' >> /etc/vim/vimrc
	echo -e " " >> /etc/vim/vimrc
	echo -e 'syntax on               "Language coloration' >> /etc/vim/vimrc
	echo -e 'color desert            "Colorscheme' >> /etc/vim/vimrc
	echo -e " " >> /etc/vim/vimrc

}



###### To test the script, just uncomment the following lines
#source ./check_root_rights.sh
#checkRootRights
#setupVim