#install.packages("tidyr")
#devtools::install_github("argparse", "trevorld")
suppressPackageStartupMessages(library(argparse))
suppressPackageStartupMessages(library(rlang))
suppressPackageStartupMessages(library(tidyr))
suppressPackageStartupMessages(library(dplyr))

parser <- ArgumentParser()
parser$add_argument("-a", "--annotation", help="file path of the annotation file")
parser$add_argument("-q", "--quantdir", help="file path of directory containing salmon's quantification files")
parser$add_argument("-o", "--outputdir", help="file path of the snp genotype file")
parser$add_argument("-m", "--meanthreshold", help="threshold for mean based filtering. Fitlers out those samples with mean less than threshold", type="double", default=0.1 )
parser$add_argument("-v", "--variancethreshold", help="threshold for variance based filtering. Fitlers out those samples with variance within the range of c(-threshold:+threshold) inclusively.", type="double", default=0.1 )
parser$add_argument("-s", "--scaledthreshold", help="threshold for normalized variance filtering. Filters out those genes with normalized variance within the range c(-threshold:threshold) inclusive. normalization is done via the r function scale()", type="double", default=0)
args <- parser$parse_args()


#this chunk can be made more efficient
#also keep track of directories - these will be inputs for optparse
files <- list.files(path = args$quantdir , pattern = "\\.sorted\\.genes\\.quant\\.sf", recursive = T)
sample_temp <- as.data.frame(read.table(file = paste(args$quantdir,"/",files[1], sep=""), sep ='\t', header =T))
TPM <- select(sample_temp, "Name")
names <- c("gene_id", substring(files,1 ,regexpr("_salmon", files)-1), "mean", "var", "scaled_var")
for (j in files){
  sample_temp <- as.data.frame(read.table(file = paste(args$quantdir,"/",j, sep=""), sep='\t', header=T))
  TPM <- cbind(TPM, select(sample_temp, "TPM"))
  print(paste(j,"read in"))
}
means<-rowMeans(TPM[-1])
variances<-apply(TPM[-1], 1, var)
scaledvar<-scale(variances)
TPM <-as.data.frame(cbind(TPM,means,variances,scaledvar))
warnings()
colnames(TPM)<-names
TPM <- filter(TPM, (( var > args$variancethreshold | var < -args$variancethreshold) & ( scaled_var > args$scaledthreshold | scaled_var < -args$scaledthreshold )) & mean > args$meanthreshold)
print("TPM dataframe generated")

total_annotation <- as.data.frame(read.table(file = args$annotation , sep = '\t', header =F, skip = 5))
colnames(total_annotation) <- c("chr", "source", "feature_type", "start", "stop", "score", "strand", "phase", "metadata")
total_annotation<-filter(total_annotation, feature_type == "gene")
total_annotation<-tidyr::separate(total_annotation, metadata, c("gene_id", "transcript_id"), sep = ";", extra = "drop")
total_annotation$gene_id <- gsub("gene_id\\s(.*)", "\\1", total_annotation$gene_id)
total_annotation$transcript_id <- gsub("transcript_id\\s*(.*)", "\\1", total_annotation$transcript_id)
print("total annotation data frame generated")

for (i in 1:22){
  chr_annotation <- filter(total_annotation, chr == paste("chr", i, sep=""))
  write.table(x =select(semi_join(chr_annotation, TPM, by ="gene_id"), "gene_id", "chr", "start", "stop"), file = paste(args$outputdir, "/location_sal_chr",i,sep=""), row.names = F, quote = F)#location file
  write.table(x =arrange(semi_join(select(TPM, -mean, -var, -scaled_var), chr_annotation, by = "gene_id"), gene_id), file = paste(args$outputdir, "/expression_sal_chr",i,sep=""), row.names = F, quote = F)
  print(paste("chr",i,"processed"))
}

