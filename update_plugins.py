try:
    import git
except:
    try:
        from pip import main as pipmain
    except ImportError:
        from pip._internal import main as pipmain
    pipmain(['install', 'gitpython'])
    try:
        import git
    except ImportError:
        git = None

try:
    import concurrent.futures as futures
except ImportError:
    try:
        import futures
    except ImportError:
        futures = None

import zipfile
import shutil
import tempfile
import requests
import os

# I add brackets after which does not work with auto pairs.
# auto-pairs https://github.com/jiangmiao/auto-pairs
# --- Globals ----------------------------------------------
PLUGINS = """
ale https://github.com/w0rp/ale
vim-yankstack https://github.com/maxbrunsfeld/vim-yankstack
ack.vim https://github.com/mileszs/ack.vim
bufexplorer https://github.com/jlanzarotta/bufexplorer
ctrlp.vim https://github.com/ctrlpvim/ctrlp.vim
mayansmoke https://github.com/vim-scripts/mayansmoke
nerdtree https://github.com/scrooloose/nerdtree
nginx.vim https://github.com/chr4/nginx.vim
open_file_under_cursor.vim https://github.com/amix/open_file_under_cursor.vim
tlib https://github.com/vim-scripts/tlib
vim-addon-mw-utils https://github.com/MarcWeber/vim-addon-mw-utils
vim-bundle-mako https://github.com/sophacles/vim-bundle-mako
vim-coffee-script https://github.com/kchmck/vim-coffee-script
vim-colors-solarized https://github.com/altercation/vim-colors-solarized
vim-indent-object https://github.com/michaeljsmith/vim-indent-object
vim-less https://github.com/groenewege/vim-less
vim-pyte https://github.com/therubymug/vim-pyte
vim-snipmate https://github.com/garbas/vim-snipmate
vim-snippets https://github.com/honza/vim-snippets
vim-surround https://github.com/tpope/vim-surround
vim-expand-region https://github.com/terryma/vim-expand-region
vim-multiple-cursors https://github.com/terryma/vim-multiple-cursors
vim-fugitive https://github.com/tpope/vim-fugitive
goyo.vim https://github.com/junegunn/goyo.vim
vim-zenroom2 https://github.com/amix/vim-zenroom2
vim-repeat https://github.com/tpope/vim-repeat
vim-commentary https://github.com/tpope/vim-commentary
vim-gitgutter https://github.com/airblade/vim-gitgutter
gruvbox https://github.com/morhetz/gruvbox
vim-flake8 https://github.com/nvie/vim-flake8
vim-pug https://github.com/digitaltoad/vim-pug
lightline.vim https://github.com/itchyny/lightline.vim
lightline-ale https://github.com/maximbaz/lightline-ale
vim-abolish https://github.com/tpope/tpope-vim-abolish
rust.vim https://github.com/rust-lang/rust.vim
vim-markdown https://github.com/plasticboy/vim-markdown
vim-gist https://github.com/mattn/vim-gist
vim-ruby https://github.com/vim-ruby/vim-ruby
typescript-vim https://github.com/leafgarland/typescript-vim
vim-javascript https://github.com/pangloss/vim-javascript
vim-python-pep8-indent https://github.com/Vimjas/vim-python-pep8-indent
mru.vim https://github.com/vim-scripts/mru.vim
""".strip()

REPO_PLUGINS = """
tagbar https://github.com/preservim/tagbar
vim-polyglot https://github.com/sheerun/vim-polyglot
YouCompleteMe https://github.com/ycm-core/YouCompleteMe
""".strip()

GITHUB_ZIP = "%s/archive/master.zip"

ROOT_DIR = os.getcwd()
SOURCE_DIR = os.path.join(os.path.dirname(__file__), "sources_non_forked")
REPO_PLUGINS_DIR = os.path.join(os.path.dirname(__file__), "my_plugins")


def download_extract_replace(plugin_name, zip_path, temp_dir, source_dir):
    temp_zip_path = os.path.join(temp_dir, plugin_name)

    # Download and extract file in temp dir
    req = requests.get(zip_path)
    open(temp_zip_path, "wb").write(req.content)

    zip_f = zipfile.ZipFile(temp_zip_path)
    zip_f.extractall(temp_dir)

    plugin_temp_path = os.path.join(
        temp_dir, os.path.join(temp_dir, "%s-master" % plugin_name)
    )

    # Remove the current plugin and replace it with the extracted
    plugin_dest_path = os.path.join(source_dir, plugin_name)

    try:
        shutil.rmtree(plugin_dest_path)
    except OSError:
        pass

    shutil.move(plugin_temp_path, plugin_dest_path)
    print("Updated {0}".format(plugin_name))

def git_clone_repo(repo_name, repo_remote, source_dir):
    repo_path = f'{source_dir}/{repo_name}'
    #print(repo_path, repo_remote)
    if not os.getcwd() == source_dir:
        os.chdir(source_dir)

    if os.path.isdir(repo_name):
        print(f'git pull {repo_name}', flush = True)
        repo = git.Repo(repo_name)
        repo.git.pull(recursive = True)
    else:
        print(f'git clone {repo_remote, repo_name}', flush = True)
        try:
            repo = git.Repo.clone_from(repo_remote, repo_name, recursive = True)
        except Exception as e:
            print(f'\n')
            print(e.args)
    print("git Updated {0}".format(repo_name))


def update(plugin):
    name, github_url = plugin.split(" ")
    zip_path = GITHUB_ZIP % github_url
    source_dir = f'{ROOT_DIR}/{SOURCE_DIR}'
    download_extract_replace(name, zip_path, temp_directory, source_dir)

def git_update(plugin):
    name, github_url = plugin.split(" ")
    source_dir = f'{ROOT_DIR}/{REPO_PLUGINS_DIR}'
    git_clone_repo(name, github_url, source_dir)

if __name__ == "__main__":
    temp_directory = tempfile.mkdtemp()

    try:
        if futures:
            with futures.ThreadPoolExecutor(16) as executor:
                zip_result = executor.map(update, PLUGINS.splitlines())
                if git:
                    git_result = executor.map(git_update, REPO_PLUGINS.splitlines())

        else:
            [update(x) for x in PLUGINS.splitlines()]
            if git:
                [git_update(x) for x in REPO_PLUGINS.splitlines()]
    finally:
        shutil.rmtree(temp_directory)
