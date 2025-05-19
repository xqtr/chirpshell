```
  ___ _    _          ___ _        _ _ 
 / __| |_ (_)_ _ _ __/ __| |_  ___| | |
| (__| ' \| | '_| '_ \__ \ ' \/ -_) | |
 \___|_||_|_|_| | .__/___/_||_\___|_|_|
                |_|        
```

# ChirpShell

A BASH script that provides a TUI (Terminal User Interface) to the command line program of Chirp, using menus with FZF. The project is WIP (work in progress). Some features are not implemented, as chirp has not very good documentation. Any help is appreciated.

## Features

- All features provided from cli chirp program, like download/upload memory
- Edit channel on the fly
- View settings of dumped memory
- Save multiple memory dumps
- Select Radio
- Select Port

## Dependencies

- fzf
- chirp
- Midnight Commander / mc (optional)

  
## Usage

Run the script... 
1. Select the model of your radio
2. Select the Port to use (Default is /dev/ttyUSB0)
3. Download Radio memory.

After that, use the menu to edit/view channels, settings etc.

## License

This project is licensed under the GPL3 License. See the [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please feel free to submit a pull request or open an issue for any suggestions or improvements.
