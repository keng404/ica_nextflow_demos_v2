process READS_SUMMARY {
    label 'process_low'
    container "${ workflow.containerEngine == 'singularity' &&
                    !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/r-magrittr:1.5--r3.2.2_0' :
        'quay.io/biocontainers/r-magrittr:1.5--r3.2.2_0' }"
    input:
    path stat
    output:
    path "*.{csv,json}"           , emit: summary
    path "versions.yml"           , emit: versions
    script:
    """
    #!/usr/bin/env Rscript
    versions <- c("${task.process}:",
        paste0("    R:", paste(R.version\$major, R.version\$minor, sep=".")))
    writeLines(versions, "versions.yml") # wirte versions.yml
    fs <- dir(".", "*.reads_stats.csv")
    if(length(fs)>0){
        df <- do.call(rbind, lapply(fs, read.csv))
        con <- file("reads_summary.csv", open="wt")
        write.csv(df, con, row.names=FALSE)
        close(con)
    }
    fs <- dir(".", "*.summary.out\$")
    if(length(fs)>0){
        df <- t(do.call(cbind, lapply(fs, read.delim, header=FALSE, row.names=1)))
        df <- gsub(",", "", df)
        mode(df) <- "numeric"
        df <- cbind(sample=sub(".summary.out", "", basename(fs)), df)
        con <- file("pairsqc_summary_out.csv", open="wt")
        write.csv(df, con, row.names=FALSE)
        close(con)
    }
    fs <- dir(".", "^summary")
    if(length(fs)>0){
        df <- do.call(rbind, lapply(fs, read.delim, header=TRUE, sep=" "))
        df[, 1] <- sub("summary.(.*?).txt", "\\\\1", basename(fs))
        write.csv(df, "MAPS_summary_out.csv", row.names=FALSE)
    }
    fs <- dir(".", "*.distance.vs.proportion.csv\$")
    if(length(fs)>0){
        dfs <- lapply(fs, function(.f){
            x <- read.csv(.f)[, -2, drop=FALSE]
            colnames(x)[-1] <- paste0(sub("distance.vs.proportion.csv", "", .f), colnames(x)[-1])
            x
        })
        json <- lapply(dfs, function(.ele){
            ## convert to list, named as colnames, for the vectors in list, named as distance
            .df <- as.data.frame(.ele[, -1])
            .df <- as.list(.df)
            .df <- lapply(.df, function(.e){
                names(.e) <- .ele[, 1]
                as.list(.e)
            })
            .df
        })
        json <- mapply(json, rainbow(n=length(json)), FUN=function(.ele, .color){
            .ele <- sapply(.ele, function(.e){
                x <- names(.e)
                y <- .e
                .e <- paste('{ "x":', x, ', "y":', y, ', "color":"', .color, '"', "}")
                .e <- paste(.e, collapse=", ")
                paste("[", .e, "]")
            })
            .ele <- paste0('"', names(.ele), '" : ', .ele)
            .ele <- paste(.ele, collapse=", ")
        })
        json <- c(
                "{",
                '"id":"pairs_reads_proportion",',
                '"data":{',
                paste(unlist(json), collapse=", "),
                "}",
                "}")
        writeLines(json, "dist.prop.qc.json")
        ## merge by first columns
        mg <- function(...){
            merge(..., all = TRUE)
        }
        dfs <- Reduce(mg, dfs)
        write.table(t(dfs), "dist.prop.csv", col.names=FALSE, quote=FALSE, sep=",", row.names=TRUE)
    }
    """
}
