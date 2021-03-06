function opts = optdiffscale(sigmaI,W)
  %disp(W)
  maxisotropic_measure = 0;
  %%Calculation of optimal s for calculating sigmaD by maximizing isotropic measure
  for s = 50:75
    sofD = s/100;
    sigmaD = sofD*sigmaI;
    g = fspecial('gaussian',3,sigmaD);
    [Lwx,Lwy] = gradient(g);
    gw = fspecial('gaussian',3,sigmaI);
    imgwx = conv2(W,Lwx,'same');
    imgwy = conv2(W,Lwy,'same');
    imgwxx = imgwx.^2;
    imgwxx = conv2(imgwxx,gw,'same');
    imgwyy = imgwy.^2;
    imgwyy = conv2(imgwyy,gw,'same');
    imgwxy = imgwx.*imgwy;
    imgwxy = conv2(imgwxy,gw,'same');
    isotropic_measure = isotropicmeasure(imgwxx,imgwyy,imgwxy,sigmaD);
    if isotropic_measure>maxisotropic_measure
        maxisotropic_measure = isotropic_measure;
        opts = sofD;
    end
  end
end
