# iconfont
transform svg to OC *.m  (iconfont)

原理： svg是一种矢量图，通过path路径来确定最终的图形。 svg的格式是基于xml的，所以想到通过解析xml来获取attribute节点，转换成属性。最终生成oc的文件。
用法：在命令行输入 ruby filter.rb xx.svg 
（确定该脚本拥有可执行权限）
可以修改 源文件的here document的 一些自定义文字，类名前缀等，适应自己的工程
