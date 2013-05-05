//
//  MODJsonParserV8.m
//  mongo-objc-driver
//
//  Created by Jérôme Lebel on 01/05/13.
//
//

#import "MODJsonParserV8.h"
#import "v8.h"

static const char* ToCString(const v8::String::Utf8Value& value)
{
    return *value ? *value : "<string conversion failed>";
}

static void ReportException(v8::Isolate* isolate, v8::TryCatch* try_catch)
{
    v8::HandleScope handle_scope(isolate);
    v8::String::Utf8Value exception(try_catch->Exception());
    const char* exception_string = ToCString(exception);
    v8::Handle<v8::Message> message = try_catch->Message();
    if (message.IsEmpty()) {
        // V8 didn't provide any extra information about this error; just
        // print the exception.
        fprintf(stderr, "%s\n", exception_string);
    } else {
        // Print (filename):(line number): (message).
        v8::String::Utf8Value filename(message->GetScriptResourceName());
        const char* filename_string = ToCString(filename);
        int linenum = message->GetLineNumber();
        fprintf(stderr, "%s:%i: %s\n", filename_string, linenum, exception_string);
        // Print line of source code.
        v8::String::Utf8Value sourceline(message->GetSourceLine());
        const char* sourceline_string = ToCString(sourceline);
        fprintf(stderr, "%s\n", sourceline_string);
        // Print wavy underline (GetUnderline is deprecated).
        int start = message->GetStartColumn();
        for (int i = 0; i < start; i++) {
            fprintf(stderr, " ");
        }
        int end = message->GetEndColumn();
        for (int i = start; i < end; i++) {
            fprintf(stderr, "^");
        }
        fprintf(stderr, "\n");
        v8::String::Utf8Value stack_trace(try_catch->StackTrace());
        if (stack_trace.length() > 0) {
            const char* stack_trace_string = ToCString(stack_trace);
            fprintf(stderr, "%s\n", stack_trace_string);
        }
    }
}

#define CONTEXT_MARGIN 10

static NSError *errorWithV8Exception(v8::Isolate* isolate, v8::TryCatch* try_catch)
{
    NSError *error;
    NSString *description;
    NSMutableDictionary *userInfo;
    
    userInfo = [[NSMutableDictionary alloc] init];
    v8::HandleScope handle_scope(isolate);
    v8::String::Utf8Value exception(try_catch->Exception());
    const char* exception_string = ToCString(exception);
    v8::Handle<v8::Message> message = try_catch->Message();
    if (message.IsEmpty()) {
        description = [[NSString alloc] initWithCString:exception_string encoding:NSUTF8StringEncoding];
    } else {
        NSString *source;
        NSRange range;
        
        // Print line of source code.
        v8::String::Utf8Value sourceline(message->GetSourceLine());
        const char* sourceline_string = ToCString(sourceline);
        range.location = message->GetStartColumn();
        range.length = message->GetEndColumn() - message->GetStartColumn();
        [userInfo setObject:NSStringFromRange(range) forKey:@"ErrorRange"];
        if (range.location < CONTEXT_MARGIN) {
            range.length += range.location;
            range.location = 0;
        } else {
            range.location -= CONTEXT_MARGIN;
            range.length += CONTEXT_MARGIN;
        }
        range.length += CONTEXT_MARGIN;
        if (range.location + range.length > strlen(sourceline_string)) {
            range.length -= range.location + range.length - strlen(sourceline_string);
        }
        source = [[NSString alloc] initWithBytes:sourceline_string + range.location length:range.length encoding:NSUTF8StringEncoding];
        description = [[NSString alloc] initWithFormat:@"%s - \"%@\"", exception_string, source];
        [source release];
    }
    [userInfo setObject:description forKey:NSLocalizedDescriptionKey];
    error = [NSError errorWithDomain:MODJsonParserV8ErrorDomain code:-1 userInfo:userInfo];
    [userInfo release];
    [description release];
    return error;
}

static v8::Persistent<v8::Context> CreateShellContext()
{
    // Create a template for the global object.
    v8::Handle<v8::ObjectTemplate> global = v8::ObjectTemplate::New();
    // Bind the global 'print' function to the C++ Print callback.
//    global->Set(v8::String::New("print"), v8::FunctionTemplate::New(Print));
    // Bind the global 'read' function to the C++ Read callback.
//    global->Set(v8::String::New("read"), v8::FunctionTemplate::New(Read));
    // Bind the global 'load' function to the C++ Load callback.
//    global->Set(v8::String::New("load"), v8::FunctionTemplate::New(Load));
    // Bind the 'quit' function
//    global->Set(v8::String::New("quit"), v8::FunctionTemplate::New(Quit));
    // Bind the 'version' function
//    global->Set(v8::String::New("version"), v8::FunctionTemplate::New(Version));
    
    return v8::Context::New(NULL, global);
}

static NSError *ExecuteString(v8::Isolate* isolate,
                   v8::Handle<v8::String> source,
                   v8::Handle<v8::Value> name,
                   bool print_result) {
    v8::HandleScope handle_scope(isolate);
    v8::TryCatch try_catch;
    v8::Handle<v8::Script> script = v8::Script::Compile(source, name);
    if (script.IsEmpty()) {
        // Print errors that happened during compilation.
        return errorWithV8Exception(isolate, &try_catch);
    } else {
        v8::Handle<v8::Value> result = script->Run();
        if (result.IsEmpty()) {
            assert(try_catch.HasCaught());
            // Print errors that happened during execution.
            return errorWithV8Exception(isolate, &try_catch);
        } else {
            assert(!try_catch.HasCaught());
            if (print_result && !result->IsUndefined()) {
                // If all went well and the result wasn't undefined then print
                // the returned value.
                v8::String::Utf8Value str(result);
                const char* cstr = ToCString(str);
                printf("%s\n", cstr);
            }
            return nil;
        }
    }
}

static NSError *RunShell(v8::Handle<v8::Context> context, const char *json)
{
    // Enter the execution environment before evaluating any code.
    v8::Context::Scope context_scope(context);
    v8::Local<v8::String> name(v8::String::New("(shell)"));
    {
        v8::HandleScope handle_scope(context->GetIsolate());
        return ExecuteString(context->GetIsolate(),
                      v8::String::New(json),
                      name,
                      true);
    }
}

@implementation MODJsonParserV8

- (size_t)parseJsonWithCstring:(const char *)json error:(NSError **)error
{
    v8::Isolate* isolate = v8::Isolate::GetCurrent();
    {
        v8::HandleScope handle_scope(isolate);
        v8::Persistent<v8::Context> context = CreateShellContext();
        if (context.IsEmpty()) {
            return 0;
        }
        context->Enter();
        *error = RunShell(context, json);
        context->Exit();
        context.Dispose(isolate);
    }
    v8::V8::Dispose();
    return strlen(json);
}

- (BOOL)parsingDone
{
    return YES;
}

- (id)mainObject
{
    return nil;
}

@end
