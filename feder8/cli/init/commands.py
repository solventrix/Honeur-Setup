from cli.globals import Globals
import click
import questionary
import docker

@click.group()
def init():
    """Initialize command for different components."""
    pass

@init.command()
@click.option('-ta', '--therapeutic-area', type=click.Choice(Globals.all_therapeutic_areas.keys()))
def config_server(therapeutic_area):
    if therapeutic_area is None:
        therapeutic_area = questionary.select("Name of Therapeutic Area?", choices=Globals.all_therapeutic_areas.keys()).ask()

@init.command()
@click.option('-ta', '--therapeutic-area', type=click.Choice(Globals.all_therapeutic_areas.keys()))
def postgres(therapeutic_area):
    if therapeutic_area is None:
        therapeutic_area = questionary.select("Name of Therapeutic Area?", choices=Globals.all_therapeutic_areas.keys()).ask()
    

@init.command()
@click.option('-ta', '--therapeutic-area', type=click.Choice(Globals.all_therapeutic_areas.keys()))
def local_portal(therapeutic_area):
    if therapeutic_area is None:
        therapeutic_area = questionary.select("Name of Therapeutic Area?", choices=Globals.all_therapeutic_areas.keys()).ask()

@init.command()
@click.option('-ta', '--therapeutic-area', type=click.Choice(Globals.all_therapeutic_areas.keys()))
def atlas_webapi(therapeutic_area):
    if therapeutic_area is None:
        therapeutic_area = questionary.select("Name of Therapeutic Area?", choices=Globals.all_therapeutic_areas.keys()).ask()

@init.command()
@click.option('-ta', '--therapeutic-area', type=click.Choice(Globals.all_therapeutic_areas.keys()))
def zeppelin(therapeutic_area):
    if therapeutic_area is None:
        therapeutic_area = questionary.select("Name of Therapeutic Area?", choices=Globals.all_therapeutic_areas.keys()).ask()

@init.command()
@click.option('-ta', '--therapeutic-area', type=click.Choice(Globals.all_therapeutic_areas.keys()))
def user_management(therapeutic_area):
    if therapeutic_area is None:
        therapeutic_area = questionary.select("Name of Therapeutic Area?", choices=Globals.all_therapeutic_areas.keys()).ask()

@init.command()
@click.option('-ta', '--therapeutic-area', type=click.Choice(Globals.all_therapeutic_areas.keys()))
def distributed_analytics(therapeutic_area):
    if therapeutic_area is None:
        therapeutic_area = questionary.select("Name of Therapeutic Area?", choices=Globals.all_therapeutic_areas.keys()).ask()

@init.command()
@click.option('-ta', '--therapeutic-area', type=click.Choice(Globals.all_therapeutic_areas.keys()))
def feder8_studio(therapeutic_area):
    if therapeutic_area is None:
        therapeutic_area = questionary.select("Name of Therapeutic Area?", choices=Globals.all_therapeutic_areas.keys()).ask()
