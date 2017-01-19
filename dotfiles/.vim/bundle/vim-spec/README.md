# vim-spec

<a href="https://copr.fedorainfracloud.org/coprs/fszymanski/vim-spec/package/vim-spec/"><img src="https://copr.fedorainfracloud.org/coprs/fszymanski/vim-spec/package/vim-spec/status_image/last_build.png" /></a>

RPM spec file plugin for Vim.

## Installation

To install vim-spec, use your favorite Vim/Neovim plugin manager (recommended).

- [Pathogen](https://github.com/tpope/vim-pathogen)

  Run the following command in your terminal emulator:

  ```sh
  cd ~/.vim/bundle && git clone https://github.com/fszymanski/vim-spec
  ```

- [Plug](https://github.com/junegunn/vim-plug)

  Add the following code to your `.vimrc`:

  ```vim
  Plug 'fszymanski/vim-spec'
  ```

  Source the `.vimrc` file and execute:

  ```vim
  :PlugInstall
  ```

[Fedora](https://getfedora.org/) users can find an RPM package in my
[Copr](http://copr.fedorainfracloud.org/coprs/fszymanski/vim-spec/) repository.

```sh
# Enable the repository
sudo dnf copr enable fszymanski/vim-spec
# Install the package
sudo dnf install vim-spec
```

## Documentation

See the [`:h spec.txt`](https://github.com/fszymanski/vim-spec/blob/master/doc/spec.txt) for more details.

## TODO :pushpin:

- [ ] Syntax highlighting

## License

[MIT](https://github.com/fszymanski/vim-spec/blob/master/LICENSE)
