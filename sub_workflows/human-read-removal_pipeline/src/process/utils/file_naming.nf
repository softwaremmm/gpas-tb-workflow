def get_clean_1_file_name(sample_name) {
  if (sample_name == null) {
    error('sample name is empty')
  }

  def clean_1_name = "${sample_name}_1.clean_1.fastq.gz"
  println("File name: ${clean_1_name}")
  return clean_1_name
}

def get_clean_2_file_name(sample_name) {
  if (sample_name == null) {
    error('sample name is empty')
  }

  def clean_2_name = "${sample_name}_2.clean_2.fastq.gz"
  println("File name: ${clean_2_name}")
  return clean_2_name
}

def get_report_file_name() {
  return "decontamination-log.json"
}
