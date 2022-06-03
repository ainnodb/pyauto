#!/opt/bosap/toolset/bin/python3 -E
"""
Check if port is open on remote system
"""
import click
import socket


@click.command()
@click.argument('hostname')
@click.argument('port', type=int)
@click.option('-t', '--timeout', type=int, default=3)
def check_port(hostname: str, port: int, timeout: int = 3):
    """Check if PORT on HOSTNAME is open"""
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.settimeout(timeout)
    try:
        s.connect((hostname, port))
        s.shutdown(socket.SHUT_RDWR)
    except:
        exit(8)
    finally:
        s.close()
    exit(0)


if __name__ == '__main__':
    check_port()
