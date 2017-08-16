//
//  ViewController.m
//  HRMulLanguage
//
//  Created by ZhangHeng on 2016/12/13.
//  Copyright © 2016年 ZhangHeng. All rights reserved.
//

#import "ViewController.h"
#import <GDataXML-HTML/GDataXMLNode.h>

@interface ViewController ()
{
    //保存excel里按竖行排列的数组
    NSMutableArray  *mainDataArray;
    //每条竖着的单条信息
    NSMutableArray  *listRow;
    
    NSMutableArray *allDatas;
    
    IBOutlet UITextView     *outputText;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(IBAction)startParse:(id)sender{
    allDatas = @[].mutableCopy;
    
    NSData *data = [[NSData alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"languages" ofType:@"xml"]];
    NSError *error;
    GDataXMLDocument *xmlDoc = [[GDataXMLDocument alloc] initWithData:data error:&error];
    if(error){
        NSLog(@"%@",error);
    }else{
        NSLog(@"%@",xmlDoc.rootElement);
    }
    
    //表单列表
    NSArray *sheets = [xmlDoc.rootElement elementsForName:@"Worksheet"];
    if(sheets){
        NSLog(@"%@",sheets);
        //只取第一个
        GDataXMLElement *firstTable = [sheets firstObject];
        //表单内部表格,一般只有一个
        NSArray *tables = [firstTable elementsForName:@"Table"];
        if(tables){
            //还是取第一个
            GDataXMLElement *firstTable = tables[0];
            NSArray *rows = [firstTable elementsForName:@"Row"];
            if(rows){
                NSLog(@"%@",rows);
                for(GDataXMLElement *row in rows){
                    NSArray *cells = [row elementsForName:@"Cell"];
                    NSMutableString *values = @"".mutableCopy;
                    for(GDataXMLElement *cell in cells){
                        GDataXMLElement *data = [[cell elementsForName:@"Data"] firstObject];
                        if([cells indexOfObject:cell] == cells.count - 1)
                            [values appendString:data.stringValue?data.stringValue:@""];
                        else
                            [values appendFormat:@"%@|",data.stringValue?data.stringValue:@""];
                    }
                    [allDatas addObject:values];
                }
            }
        }
    }
}

//进行装配最后的值
-(void)configDataWithArray:(NSArray *)array{
    NSMutableString *showPath = @"".mutableCopy;
    //分成上方的语言名
    NSArray    *languaNames = [[array firstObject] componentsSeparatedByString:@"|"];
    //第一项为各个语言名
    for(NSString *languageName in languaNames){
        NSUInteger index = [languaNames indexOfObject:languageName];
        
        NSMutableString *finalWriteString = [NSMutableString new];
        //后面的从第二行开始为对应的值
        for(int i = 1; i < array.count; i ++){
            NSString *rowString = array[i];
            if([[rowString componentsSeparatedByString:@"|"] count] > languaNames.count){
                //去掉最前面有 =的部分
                NSString *key = [[rowString componentsSeparatedByString:@"|"] firstObject];
                [finalWriteString appendFormat:@"\"%@\" = ",[self removeUnnecesaryString:key]];
                NSString *valueString = [[rowString componentsSeparatedByString:@"|"] objectAtIndex:index + 1];
                [finalWriteString appendFormat:@"\"%@\";\n",[self removeUnnecesaryString:valueString]];
                
            }
        }
        NSData *writeData = [finalWriteString dataUsingEncoding:NSUTF8StringEncoding];
        NSString *writePath = [[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.txt",languageName]];
        [writeData writeToFile:writePath atomically:YES];
        [showPath appendFormat:@"%@\n",writePath];
        [outputText setText:showPath];
    }
}

-(NSString *)removeUnnecesaryString:(NSString *)oriString{
    NSString *first = [oriString stringByReplacingOccurrencesOfString:@"=" withString:@""];
    first = [first stringByReplacingOccurrencesOfString:@";" withString:@""];
    first = [first stringByReplacingOccurrencesOfString:@"\"" withString:@""];
    return [first stringByReplacingOccurrencesOfString:@" " withString:@""];
}

-(IBAction)saveResult:(id)sender{
    if(allDatas.count == 0)
        return;
    [self configDataWithArray:allDatas];
}

@end
