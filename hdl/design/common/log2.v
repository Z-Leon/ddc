function integer log2;
  input integer value;
  for (log2=0; value>0; log2=log2+1)
    value = value>>1;
endfunction