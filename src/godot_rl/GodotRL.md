# GodotRL

GodotRL is a reinforcement learning environment for the Godot game engine.
It is designed to be a general purpose environment for training agents in Godot games.

## Run GodotRL server

### Using editor and server

```bash
export WORKSPACE_DIR=../../workspace
python main.py --experiment_dir "$WORKSPACE_DIR/logs" --experiment_name brotato_experiment --viz --speedup 3 
```

### Using standalone
    
```bash
export WORKSPACE_DIR=../../workspace
python main.py --experiment_dir "$WORKSPACE_DIR/logs" --experiment_name brotato_experiment --viz --speedup 3
```

# Command Line Options

## `--trainer`

- **Default**: `sb3`
- **Choices**: `sb3`, `sf`, `rllib`
- **Help**: Framework to use (rllib, sf, sb3)

## `--env_path`

- **Default**: `None`
- **Help**: Godot binary to use

## `--config_file`

- **Default**: `ppo_test.yaml`
- **Help**: The yaml config file \[only for rllib\]

## `--restore`

- **Default**: `None`
- **Help**: The location of a checkpoint to restore from

## `--eval`

- **Default**: `False`
- **Action**: `store_true`
- **Help**: Whether to eval the model

## `--speedup`

- **Default**: `1`
- **Help**: Whether to speed up the physics in the env

## `--export`

- **Default**: `False`
- **Action**: `store_true`
- **Help**: Whether to export the model

## `--num_gpus`

- **Default**: `None`
- **Help**: Number of GPUs to use \[only for rllib\]

## `--experiment_dir`

- **Default**: `None`
- **Type**: `str`
- **Help**: The name of the experiment directory, in which the tensorboard logs are getting stored

## `--experiment_name`

- **Default**: `experiment`
- **Help**: The name of the experiment, which will be displayed in tensorboard

## `--viz`

- **Default**: `False`
- **Action**: `store_true`
- **Help**: Whether to visualize one process

## `--seed`

- **Default**: `0`
- **Help**: Seed of the experiment

