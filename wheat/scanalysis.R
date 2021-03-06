library(gdata);
library(ggplot2);

#Calibrate pixels

sum_intensities <- function(data)
{
  
  copydata = data;
  copydata = data.frame(copydata, sumint = sapply(rownames(copydata), 
              function(x) sum(copydata[x,3:131])));
  return(copydata);
  
}



convert2hex <- function(data1, data2)
{
  copydata1 = data1;
  copydata2 = data2;
  hexlist = c();
  
  for(i in 1:length(copydata1))
  {
    idx = which(copydata2$i == copydata1[i])
    hexlist = append(hexlist, as.character(copydata2[idx,5]));
    
  }
  return(hexlist)
}


#scsub = scsub[order(as.Date(cdata$time, format="%y%m%d")),]
## 
# vc = c();
# for(i in 3:dim(sc)[2])
# {
#   vc = append(vc,mean(sc[,i]))
# }
# v = which(vc <= 10);
# v = v+2;
# scc1 = sc[,c(-3, -123:-127, -v)];




get_subdata = function(data, conver_table, intens)
{

 
  copydata = data;
  # I us want to use the same intensities # Vey crude way but it seems they're the most relevants.
  
  u = colnames(copydata) %in% intens; # Search for intens
  scc1= data.frame(idtag = copydata$idtag, 
                   time = copydata$time, copydata[,u]); # Create frame with sel intensi 
  freq = colnames(scc1)[3:dim(scc1)[2]];
  freq = as.numeric(sub("X", "", freq));
  colnames(scc1)[3:dim(scc1)[2]] = freq; # Delete X in columns
  #write.table(scc1, file='t.csv', sep=',', row.names=F);
  
  mm = as.matrix(scc1[, 3:dim(scc1)[2]]); # Deletes -4
  vector_data = unmatrix(mm,byrow=T); # Convert matrix into vector
  vector_data = as.numeric(vector_data); # Convert values to numeric
  idtag = as.character(unique(scc1$idtag)); # Unique idtags
  time = as.character(unique(scc1$time)) # unique time points
  hexlist = convert2hex(freq, conver_table); # 
  conveg = expand.grid(idtag=idtag, intensity=hexlist,time=time);
  cdata = data.frame(conveg, value=vector_data);
  #cdatacal = calibrate_data(cdata);
  return(cdata);
}

# Take row means

takeMeans <- function(x) 
{
  x1 = rapply(x, mean);
  x1['time'] = names(x); 
  return(x1)
}

# Plot the thing;
print_plot = function(data)
{
  copydata = data;
  p = ggplot(copydata,aes(x = time, y = value, fill=intensity, group=intensity)) +
    geom_area() + geom_line(aes(ymax=value), position="stack") +
    scale_fill_manual(values = as.character(unique(copydata$intensity))) + 
    theme(axis.text.x = element_text(angle = 90, hjust = 1)) + ggtitle(idtagname);
  print(p);
}

# subset of data
average_similar_measures = function(data, featurename)
{
  copydata = data;
  copydata[[featurename]] = factor(copydata[[featurename]]);
  #print(plantid)
  # Arrange new dataset
  l <- split(copydata, copydata[[featurename]]);
  h <- do.call(rbind, lapply(1:length(l), function(x) takeMeans(l[x])));
  h = h[,c(-1,-2)];
  h = h[,c(dim(h)[2], 1:(dim(h)[2]-1))]
  h <- data.frame(idtag=unique(copydata$idtag), h);
  colnames(h)[3:(dim(h)[2])] <- colnames(scsub)[3:(dim(scsub)[2])];
  return(h);
}

calibratedata = function(data)
{
  copydata = data;
  for(tdate in unique(copydata$time))
  {
    t = which(copydata$time == tdate);
    for(i in 3:(ncol(copydata)-2))
    {
      if(as.Date(tdate) <= as.Date("2015-04-01")) 
      { 
        copydata[t,i] = copydata[t,i]*0.27;
      }
      else 
      { 
        copydata[t,i] = copydata[t,i]*0.56;
      }
    }
  }    
  return(copydata)
}


convert2numeric = function(data, col_list)
{
  copydata=data;
  for(cname in col_list)
  {
    copydata[[cname]] = as.numeric(as.character(copydata[[cname]]))
  }
  return(copydata);
}

break();
doodle = read.table('doodle.csv', header=T, sep=',');
freqs = colnames(doodle)[3:dim(doodle)[2]];
freqs = as.numeric(sub("X", "", freqs));
colnames(doodle)[3:dim(doodle)[2]] = freqs;
groundtruth = read.table('groundtruth.csv', header=TRUE, sep=',');

# Read table with frequencies
it = read.table('contable.csv', header=T, sep=',');
it = data.frame(it, hex=rgb(it[,2:4], max=255));
# Select intensities
intens = c(1,4,5,16,20,21,24,25,26,27,30,31,32,50,54,55,60,108,112,116);
# Select subdataset

idx = which(groundtruth$disease_score2 == 4);
idtagname_list = unique(groundtruth$barcode[idx]) 
# 
for(idtagname in idtagname_list)
{
  ix = which(doodle$idtag == idtagname);
  scsub = doodle[ix,];
  h =  average_similar_measures(scsub, 'timestamp');
  hh = convert2numeric(h, colnames(h)[3:(ncol(h)-2)])
  hh = calibratedata(hh);
  cdatacal = get_subdata(hh, it, intens);
  print_plot(cdatacal);
  if(readline(idtagname) == 'q') { break; }
}

write.table(hh, file='W8-184112.csv', sep=',', quote = F, row.names=F)

avgdata = read.table('avgData.csv', sep=',', header=TRUE);
colnames(avgdata) = c('idtag','time', as.character(1:(ncol(avgdata)-2)));
cdatacal = get_subdata(avgdata, it, intens);
print_plot(cdatacal);


f = get_subdata(avgdata, it, intens);
print_plot(f);
