# gatekeeper_pipeline

This pipeline should be use to peform check quality in sequence data.

Parameters

**input_dir**  = A directory containing pairs of fastq(.gz) files

**output_dir** = Output directory for results

## FASTP Parameters ## 

**length_required**  Reads shorter than _length_required_ will be discarded, default is 15. (int [=15])

Applied: --length_required 50 

**average_qual** if one read's average quality score <avg_qual, then this read/pair is discarded. Default 0 means no requirement (int [=0])

Applied: --average_qual 10

**--low_complexity_filter** enable low complexity filter. The complexity is defined as the percentage of base that is different from its next base (base[i] != base[i+1]).


**--correction** enable base correction in overlapped regions (only for PE data), default is disabled

### per read cutting by quality  ###

**--cut_right** move a sliding window from front to tail, if meet one window with mean quality < threshold, drop the bases in the window and the right part, and then stop.


**--cut_tail** move a sliding window from tail (3') to front, drop the bases in the window if its mean quality is below cut_mean_quality, stop otherwise. 

**--cut_tail_window_size** the window size option of cut_tail, default to cut_window_size if not specified (int [=4])

Applied: --cut_tail_window_size 1

**--cut_tail_window_size** the mean quality requirement option for cut_tail, default to cut_mean_quality if not specified (int [=20])

Applied:  --cut_tail_mean_quality 20 (default)


## Testing 

Testing the python code requires `pytest` (listed in the environment.yml) 

From projet's main folder: 

```console
python -m pytest tests/python/test_generate_report.py
```
